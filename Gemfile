source ENV.fetch('GEM_SOURCE', 'https://rubygems.org')

gem 'tsuga', git: 'https://github.com/mezis/tsuga.git'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.0.0'

# Use postgresql as the database for Active Record
gem 'pg'
gem 'mysql2'

# templates
gem 'haml-rails'

# load .env
gem 'dotenv-rails'

# 
# Frontend
# 

# Use SCSS for stylesheets
gem 'sass-rails', '~> 4.0.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.0.0'

# styling
gem 'compass-rails', '~> 2.0.alpha.0'
gem 'bootstrap-sass', '~> 3.0.0.0.rc'
gem "font-awesome-rails"


# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'


# 
# Production
# 

# webservers
gem 'rainbows', group: :production
gem 'thin',     group: :development

# exception reporting
gem 'sentry-raven'

# makes the app (more) 12-factor compliant
gem 'rails_12factor', group: :production


group :development do
  gem 'pry-rails'

  gem 'rspec-rails',             require:false
  gem 'guard-rspec',             require:false
  gem 'guard-rails',             require:false
end
