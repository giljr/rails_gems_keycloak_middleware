require 'jwt'
require 'net/http'
require 'json'
require 'uri'
require_relative 'configuration'

module KeycloakMiddleware
  class Middleware
    def initialize(app)
      @app = app
      @config = Configuration.new

      yield @config if block_given?
    end

    def call(env)
      puts '[KeycloakMiddleware] processing request…' if @config.debug
      load_config

      request = Rack::Request.new(env)
      session = request.session
      path = request.path_info

      case path
      when '/login'
        session[:return_to] = request.params['return_to'] || '/'
        return redirect_to_keycloak_login
      when '/auth/callback'
        return handle_callback(request)
      when '/logout'
        return handle_logout(request)
      end

      required_role = @config.protected_paths[path]
      return @app.call(env) unless required_role

      token = extract_token(request)

      unless token || session[:roles].present?
        session[:return_to] = request.fullpath
        return [302, { 'Location' => '/login' }, []]
      end

      payload = decode_token(token)
      return unauthorized('Invalid token') unless payload

      roles = payload.dig('realm_access', 'roles') || []
      return forbidden('Insufficient role') unless roles.include?(required_role)

      env['keycloak.token'] = payload
      @app.call(env)
    end

    private

    def load_config
      @realm ||= ENV.fetch('KEYCLOAK_REALM')
      @auth_server_url ||= ENV.fetch('KEYCLOAK_SITE')
      @client_id      ||= ENV.fetch('KEYCLOAK_CLIENT_ID')
      @client_secret  ||= ENV.fetch('KEYCLOAK_CLIENT_SECRET')
      @redirect_uri   ||= ENV.fetch('KEYCLOAK_REDIRECT_URI')
      @jwks           ||= fetch_jwks
    end

    def extract_token(request)
      bearer = request.get_header('HTTP_AUTHORIZATION')
      return bearer.split.last if bearer&.start_with?('Bearer ')

      request.session[:access_token]
    end

    def redirect_to_keycloak_login
      auth_uri = URI("#{@auth_server_url}/realms/#{@realm}/protocol/openid-connect/auth")
      auth_uri.query = URI.encode_www_form(
        client_id: @client_id,
        redirect_uri: @redirect_uri,
        response_type: 'code',
        scope: 'openid profile email',
        state: 'secure_random_state'
      )
      [302, { 'Location' => auth_uri.to_s }, []]
    end

    def handle_callback(request)
      code = request.params['code']
      session = request.session

      debug_puts '----------------------------------------------' if code
      debug_puts "Received authorization code: #{code}" if code

      return unauthorized('Missing authorization code') unless code

      token_response = exchange_code_for_token(code)

      debug_puts '----------------------------------------------' if code
      debug_puts "Token response: #{token_response.inspect}" if token_response
      debug_puts '----------------------------------------------' if code

      unless token_response && token_response['access_token'] && token_response['id_token']
        return unauthorized('Token exchange failed')
      end

      # Decode id_token and access_token
      decode_token(token_response['id_token'])
      decode_token(token_response['access_token'])

      # Save minimal session data
      decoded_payload = decode_token(token_response['access_token'])
      session[:user_id] = decoded_payload['sub']
      session[:roles]   = decoded_payload.dig('realm_access', 'roles') || []
      session[:access_token] = token_response['access_token']

      redirect_path =
        if @config.on_login_success
          @config.on_login_success.call(session[:roles])
        else
          '/'
        end

      [302, { 'Location' => redirect_path }, []]
    end

    def handle_logout(request)
      session = request.session
      id_token = session[:id_token]

      # clear the session
      session.clear

      logout_uri = URI("#{@auth_server_url}/realms/#{@realm}/protocol/openid-connect/logout")
      logout_uri.query = URI.encode_www_form(
        id_token_hint: id_token,
        post_logout_redirect_uri: @redirect_uri
      )

      [302, { 'Location' => logout_uri.to_s }, []]
    end

    def exchange_code_for_token(code)
      uri = URI("#{@auth_server_url}/realms/#{@realm}/protocol/openid-connect/token")
      res = Net::HTTP.post_form(uri, {
                                  client_id: @client_id,
                                  client_secret: @client_secret,
                                  grant_type: 'authorization_code',
                                  code: code,
                                  redirect_uri: @redirect_uri
                                })
      JSON.parse(res.body)
    rescue StandardError => e
      warn "Token exchange failed: #{e.message}"
      nil
    end

    def fetch_jwks
      uri = URI("#{@auth_server_url}/realms/#{@realm}/protocol/openid-connect/certs")
      response = Net::HTTP.get(uri)
      keys = JSON.parse(response)['keys']
      JWT::JWK::Set.new(keys)
    rescue StandardError => e
      warn "Failed to fetch JWKS: #{e.message}"
      JWT::JWK::Set.new([])
    end

    def decode_token(token)
      @jwks.keys.each do |jwk|
        return JWT.decode(token, jwk.public_key, true, algorithm: 'RS256').first
      rescue JWT::DecodeError
        next
      end
      nil
    end

    def unauthorized(message)
      [401, { 'Content-Type' => 'application/json' }, [{ error: message }.to_json]]
    end

    def forbidden(message)
      [403, { 'Content-Type' => 'application/json' }, [{ error: message }.to_json]]
    end

    def debug_puts(message)
      puts(message) if @config.debug
    end
  end
end
