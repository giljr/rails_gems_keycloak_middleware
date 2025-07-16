require 'keycloak_middleware/version'
require 'keycloak_middleware/middleware'

# only load generator if Rails Generators are running
require 'keycloak_middleware/generators/install/install_generator' if defined?(Rails::Generators)

module KeycloakMiddleware
end
