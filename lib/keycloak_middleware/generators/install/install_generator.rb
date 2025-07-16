require 'rails/generators'

module KeycloakMiddleware
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Instala o KeycloakMiddleware no seu app Rails'

      def create_initializer
        initializer_path = 'config/initializers/keycloak_middleware.rb'
        say_status('info', "Criando #{initializer_path}", :blue)

        create_file initializer_path, <<~RUBY
          Rails.application.config.middleware.use KeycloakMiddleware::Middleware do |config|
            # Configure os caminhos protegidos e os papéis exigidos
            config.protect "/secured", role: "user"
            config.protect "/admin", role: "admin"
          end
        RUBY
      end
    end
  end
end
