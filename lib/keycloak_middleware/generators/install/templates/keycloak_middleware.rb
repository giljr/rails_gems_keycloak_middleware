Rails.application.config.middleware.use KeycloakMiddleware::Middleware do |config|
  # Protect specific paths and define required roles
  config.protect "/secured", role: "user"
  config.protect "/admin", role: "admin"
end
