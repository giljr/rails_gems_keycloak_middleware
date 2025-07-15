require "rails/generators"

module KeycloakMiddleware
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Creates a KeycloakMiddleware initializer."

      source_root File.expand_path("templates", __dir__)

      def copy_initializer
        template "keycloak_middleware.rb", "config/initializers/keycloak_middleware.rb"
      end
    end
  end
end
