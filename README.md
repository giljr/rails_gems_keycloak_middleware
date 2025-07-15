# KeycloakMiddleware


✅ **Plug-and-play Keycloak authentication middleware for Rails apps, with configurable protected paths and roles.**

## 💄Features
```
- OpenID Connect Authorization Code Flow
- JWT validation using JWKS from Keycloak
- Role-based access control
- Configurable protected paths and roles per app
- Plug & play: no controllers or models required
```
---

We recommend adding dotenv-rails to your Gemfile for .env support:
```ruby
gem "dotenv-rails", groups: [:development, :test]
```
🔷 Protected paths and roles

Edit the initializer created at:
```
config/initializers/keycloak_middleware.rb
```
Example:
```ruby
Rails.application.config.middleware.use KeycloakMiddleware::Middleware do |config|
  config.protect "/secured", role: "user"
  config.protect "/admin", role: "admin"
end
```
You can define as many protected paths as you like.

Unlisted paths are left unprotected and pass through.

🧪 Usage

    Start your Rails app:

    bin/rails server

    Visit a protected path (/secured, /admin) — you’ll be redirected to Keycloak login.

    Once authenticated, you’re redirected back to your app.
    Users without the required roles receive a 403 Forbidden.

🧰 Development

To build and install locally for testing:
```ruby
rake install
```
To build and release to RubyGems:
```ruby
rake release
```

🚀 Quick Workflow

✅ Add gem to your app’s Gemfile:
```ruby
gem "keycloak_middleware", path: "../keycloak_middleware"
```
✅ Install dependencies:
```ruby
bundle install
```
✅ Generate the initializer:
```ruby
bin/rails generate keycloak_middleware:install
```
✅ Fill in .env or Rails credentials.

✅ Define your protected paths and roles in `config/initializers/keycloak_middleware.rb`.

✅ Done! Your middleware is active.

 
🗂 Example .env

See the included [keycloak_middleware/.env.example](.env.example/).


📜 License

MIT