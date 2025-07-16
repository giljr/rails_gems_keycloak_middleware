module KeycloakMiddleware
  class Configuration
    attr_reader :protected_paths

    def initialize
      @protected_paths = {}
    end

    def protect(path, role:)
      @protected_paths[path] = role
    end
  end
end
