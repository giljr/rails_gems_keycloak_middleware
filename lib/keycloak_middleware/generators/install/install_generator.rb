require 'rails/generators'

module KeycloakMiddleware
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc 'Instala o KeycloakMiddleware no seu app Rails'

      def add_middleware
        application_rb = 'config/application.rb'
        say_status('info', "Adicionando KeycloakMiddleware ao #{application_rb}", :blue)

        inject_into_file application_rb, after: "class Application < Rails::Application\n" do
          <<-RUBY

    # Adiciona KeycloakMiddleware para autenticação
    config.middleware.use KeycloakMiddleware::Middleware
          RUBY
        end
      end
    end
  end
end
