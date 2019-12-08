run 'pgrep spring | xargs kill -9'

# UTILITY CONSOLE COLORS
########################################
def colorize(txt)
  puts "\e[47m\e[1m\e[30m#{txt}\e[0m\e[22m\e[0m"
end

# GEMFILE
########################################
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
  source 'https://rubygems.org'
  ruby '#{RUBY_VERSION}'

  gem 'rails'
  gem 'pg', '~> 0.21'
  gem 'redis', '~> 4.0'
  gem 'puma', '~> 3.11'
  gem 'jbuilder', '~> 2.5'

  #{"gem 'bootsnap'" if Rails.version >= "5.2"}
  gem 'devise', '~> 4.6', '>= 4.6.2'
  gem 'devise-jwt', '~> 0.5.9'
  gem 'dotenv-rails', '~> 2.7', '>= 2.7.2'

  # Excel reader for seeds
  gem 'creek'

  # active admin dep
  gem 'activeadmin', '~> 2.5.0'
  gem 'inherited_resources', '~> 1.11.0'
  gem 'active_admin_flat_skin', '~> 0.1.2'
  gem 'font-awesome-sass', '~> 5.11.2'
  gem 'activeadmin_quill_editor', '~> 0.2.0'

  # Reduces boot times through caching(str) required in config/boot.rb
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
  gem 'rack-cors'

  group :development do
    # Call 'byebug' anywhere in the code to stop execution and get a debugger console
    gem 'rails_real_favicon'
    gem 'web-console', '>= 3.3.0'
  end

  group :development, :test do
    gem 'listen', '>= 3.0.5', '< 3.2'
    # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
    gem 'spring'
    gem 'spring-watcher-listen', '~> 2.0.0'
    gem 'pry-rails'
  end

RUBY

# # Ruby version
# ########################################
# file '.ruby-version', RUBY_VERSION

# Procfile
########################################
file 'Procfile', <<-YAML
web: bundle exec puma -C config/puma.rb
YAML
colorize '==> Procfile created'
# README
########################################
markdown_file_content = <<-MARKDOWN
Rails app generated with [zakaryaa/jwt-devise-templates](https://github.com/zakaryaa/rails-api-template).
MARKDOWN
file 'README.md', markdown_file_content, force: true
colorize '==> README created'
# Generators
########################################

generators = <<-RUBY
config.generators do |g|
      g.orm :active_record
      g.template_engine :erb
      g.assets false
      g.helper false
      g.test_framework  :test_unit, fixture: false
    end
RUBY
environment generators
colorize '==> generators set'

########################################
# AFTER BUNDLE
########################################
after_bundle do
  colorize '==> Start after bundle'
  run "mkdir -p app/assets/config && echo '{}' > app/assets/config/manifest.js"
  colorize '==> Created empty manifest'
  # Generators: db
  ########################################
  rails_command 'db:drop db:create db:migrate'
  colorize '==> Ran drop create & migrate DB'

  # Routes
  ########################################
  routes = <<-RUBY
    Rails.application.routes.draw do
      devise_for :users, class_name: "User"
      namespace :api, :defaults => {:format => :json} do
        namespace :v1 do
          get 'users/current', to:'users#show'
        end
      end
    end
  RUBY
  run 'rm config/routes.rb'
  file 'config/routes.rb', routes, force: true

  colorize '==> Update routes file'
#   # Git ignore
#   ########################################
  append_file '.gitignore', <<-TXT

    # See https://help.github.com/articles/ignoring-files for more about ignoring files.
    #
    # If you find yourself ignoring temporary files generated by your text editor
    # or operating system, you probably want to add a global ignore instead:
    #   git config --global core.excludesfile '~/.gitignore_global'

    # Ignore bundler config.
    /.bundle

    # Ignore the default SQLite database.
    /db/*.sqlite3
    /db/*.sqlite3-journal

    # Ignore all logfiles and tempfiles.
    /log/*
    /tmp/*
    !/log/.keep
    !/tmp/.keep

    .vscode/

    # Ignore uploaded files in development
    /storage/*
    !/storage/.keep

    .byebug_history

    # Ignore master key for decrypting credentials and more.
    /config/master.key
    .env

    /public/packs
    /public/packs-test
    /node_modules
    /yarn-error.log
    yarn-debug.log*
    .yarn-integrity
    */.DS_Store
    .DS_Store
    *.swp

  TXT

  colorize '==> Update gitignore file'

  # Devise install and controller init
  ########################################
  generate('devise:install')
  generate('devise', 'api/v1/user')

  colorize '==> Install devise & generate user model'

  user_model = <<-RUBY
    class User < ApplicationRecord
      # Include default devise modules. Others available are:
      # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
      # include Devise::JWT::RevocationStrategies::JTIMatcher

      devise :database_authenticatable,
      :registerable,
      :recoverable,
      :rememberable,
      :validatable,
      :jwt_authenticatable,
      jwt_revocation_strategy: JwtBlacklist

      @expires_in = nil
      def expires_in
        return @expires_in
      end

      def on_jwt_dispatch(token, payload)
        @expires_in = payload['exp']
      end

    end
  RUBY

  run 'rm -rf app/models/api'
  file 'app/models/user.rb', user_model, force: true

  colorize '==> Update user model'

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
    class ApplicationController < ActionController::Base
      skip_before_action :verify_authenticity_token
    end
  RUBY

  colorize '==> Created application controller'
  # Api controller
  ########################################
  #run "mkdir -p app/controllers/api/v1"
  file 'app/controllers/api/v1/base_api_controller.rb', <<-RUBY
    class Api::V1::BaseApiController < ActionController::API
      before_action :authenticate_user!
      before_action :configure_permitted_parameters, if: :devise_controller?
      before_action :set_locale

      protected

      def default_url_options
        {locale: I18n.locale == I18n.default_locale ? nil : I18n.locale}
      end

      def set_locale
        I18n.locale = params[:locale] || I18n.default_locale
      end
    end
  RUBY

  colorize '==> Created base api controller'
  # Api JWT migration
  ########################################
  file 'db/migrate/20190618141950_create_jwt_blacklists.rb', <<-RUBY
    class CreateJwtBlacklists < ActiveRecord::Migration[5.2]
      def change
        create_table :jwt_blacklist do |t|
          t.string :jti, null: false
        end
        add_index :jwt_blacklist, :jti
      end
    end
  RUBY

  colorize '==> Created base JWT migration '
  # Api JWT model
  ########################################
  file 'app/models/jwt_blacklist.rb', <<-RUBY
    class JwtBlacklist < ApplicationRecord
      include Devise::JWT::RevocationStrategies::Blacklist
      self.table_name = 'jwt_blacklist'
    end
  RUBY

  colorize '==> Created base JWT model '
  # devise JWT config
  ########################################
  run 'rm config/initializers/devise.rb'
  run 'curl -L https://raw.githubusercontent.com/zakaryaa/rails-api-template/master/devise.rb > config/initializers/devise.rb'

  colorize '==> Update devise.rb initializer '

  # devise controller update
  ########################################
  file './app/controllers/api/v1/user/registrations_controller.rb'
  file './app/controllers/api/v1/user/sessions_controller.rb'
  run 'curl -L https://raw.githubusercontent.com/zakaryaa/rails-api-template/master/registrations_controller.rb> app/controllers/api/v1/user/registrations_controller.rb'
  run 'curl -L https://raw.githubusercontent.com/zakaryaa/rails-api-template/master/sessions_controller.rb> app/controllers/api/v1/user/sessions_controller.rb'

  colorize '==> Update devise registration & session controllers '
  # Dotenv
  ########################################
  secret = rake secret
  file '.env', <<-TXT
  DEVISE_JWT_SECRET_KEY=#{secret}
  TXT
  colorize '==> Set DEVISE_JWT_SECRET_KEY '

# migrate
  #######################################
  rails_command 'db:migrate'

  colorize '==> Db migrate '
  # Clean up
  ########################################
  run "rm -rf 'app/assets/'"
  run "rm -rf 'lib/assets/'"
  run "rm -rf 'vendor/assets/'"
  run "rm -rf 'app/helpers/'"
  run "rm -rf 'app/views/layouts/application.hmtl.erb'"

#   # Git
#   ########################################
  git :init
  git add: '.'
  # git commit: "-m 'Initial commit with devise template from https://github.com/zakaryaa/rails-api-template'"
end
