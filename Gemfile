source ENV.fetch('GEM_SOURCE', 'https://rubygems.org')

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.0.0'

# Use postgresql as the database for Active Record
gem 'pg'

# templates
gem 'haml-rails'


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
gem 'compass-rails'
gem 'bootstrap-sass'
gem "font-awesome-rails"


# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

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


group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end


group :development do
  gem 'pry-rails'

  gem 'rspec-rails',             require:false
  gem 'guard-rspec',             require:false
  gem 'guard-rails',             require:false
end
