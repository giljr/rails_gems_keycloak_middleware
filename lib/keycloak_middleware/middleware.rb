require 'jwt'
require 'net/http'
require 'json'
require 'uri'
require_relative 'configuration'

module KeycloakMiddleware
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Aqui entra sua lógica de autenticação com Keycloak
      puts '[KeycloakMiddleware] processing request…'
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
      end

      required_role = @config.protected_paths[path]
      return @app.call(env) unless required_role

      token = extract_token(request)

      unless token
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
      @client_id ||= ENV.fetch('KEYCLOAK_CLIENT_ID')
      @client_secret ||= ENV.fetch('KEYCLOAK_CLIENT_SECRET')
      @redirect_uri ||= ENV.fetch('KEYCLOAK_REDIRECT_URI')
      @jwks ||= fetch_jwks
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
      puts '----------------------------------------------' if code
      puts "Received authorization code: #{code}" if code
      session = request.session
      return unauthorized('Missing authorization code') unless code

      token_response = exchange_code_for_token(code)
      puts '----------------------------------------------' if code
      puts "Token response: #{token_response.inspect}" if token_response
      puts '----------------------------------------------' if code

      if token_response && token_response['access_token']
        session[:access_token] = token_response['access_token']

        payload = decode_token(token_response['access_token'])
        roles = payload.dig('realm_access', 'roles') || []

        # Decide redirection path based on role
        redirect_path =
          if roles.include?('admin')
            '/admin'
          elsif roles.include?('user')
            '/secured'
          else
            '/'
          end

        [302, { 'Location' => redirect_path }, []]
      else
        unauthorized('Token exchange failed')
      end
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
  end
end
