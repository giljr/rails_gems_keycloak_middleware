require "rake"
require "bundler/gem_tasks"

desc "Build the gem"
task :build do
  sh "gem build keycloak_middleware.gemspec"
end

desc "Install the gem locally"
task :install => :build do
  sh "gem install ./keycloak_middleware-0.1.0.gem"
end

desc "Release the gem (build + push)"
task :release => [:build] do
  sh "gem push ./keycloak_middleware-0.1.0.gem"
end
