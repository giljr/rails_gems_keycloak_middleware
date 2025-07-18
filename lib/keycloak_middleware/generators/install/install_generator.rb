require 'rails/generators'

module KeycloakMiddleware
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Installs KeycloakMiddleware in your Rails app'

      def create_initializer
        initializer_path = 'config/initializers/keycloak_middleware.rb'
        say_status('info', "Creating #{initializer_path}", :blue)

        create_file initializer_path, <<~RUBY
          Rails.application.config.middleware.use KeycloakMiddleware::Middleware do |config|
            # Configure the protected paths and required roles
            config.debug = true
            config.protect "/secured", role: "user"
            config.protect "/admin", role: "admin"

            # Configure the redirection logic on successful login
            config.on_login_success = proc do |roles|
              if roles.include?('admin')
                '/admin'
              elsif roles.include?('user')
                '/secured'
              else
                '/'
              end
            end
          end
        RUBY
      end
    end
  end
end
