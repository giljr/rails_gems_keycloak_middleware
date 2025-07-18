module KeycloakMiddleware
  class Configuration
    attr_reader :protected_paths
    attr_accessor :debug, :on_login_success

    def initialize
      @protected_paths = {}
      @debug = false
    end

    def protect(path, role:)
      @protected_paths[path] = role
    end
  end
end
