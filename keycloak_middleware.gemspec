require_relative 'lib/keycloak_middleware/version'

Gem::Specification.new do |spec|
  spec.name          = 'keycloak_middleware'
  spec.version       = KeycloakMiddleware::VERSION
  spec.authors       = ['Gilberto Oliveira Junior']
  spec.email         = ['giljr@sefin.ro.gov.br']

  spec.summary       = 'Plug-and-play Keycloak authentication middleware for Rails apps'
  spec.description   = 'Middleware to integrate Keycloak OpenID Connect flows, role-based access, and token validation into any Rails app.'
  spec.homepage      = 'https://github.com/giljr/rails/gems/keycloak_middleware'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'README.md']
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'jwt'
  spec.add_runtime_dependency 'rails', '>= 6.0'
end
