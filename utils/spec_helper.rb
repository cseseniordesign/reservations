# load the config file
require_relative 'language'
ENV['RACK_ENV'] ||= 'development'
require_relative 'config_loader'

# set up the database connection
require_relative 'database'

# set up the app and load the test methods
require "app"
require "rack/test"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include RSpec::Matchers
end
