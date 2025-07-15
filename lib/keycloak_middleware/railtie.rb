module KeycloakMiddleware
  class Railtie < Rails::Railtie
    initializer "keycloak_middleware.insert_middleware" do |app|
      app.middleware.use KeycloakMiddleware::Middleware
    end

    rake_tasks do
      load "keycloak_middleware/tasks.rake"
    end
  end
end
