# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Claco::Application.initialize!

$stdout.sync = true

#Mongoid.logger = Logger.new(STDOUT)
#Rails.logger = Logger.new(STDOUT)

Log4r::Logger.new("Application Log")

#Rails.logger = Log4r::Logger.new("Application Log")

#Rails::Initializer.run do |config|
#	config.logger = Logger.new(File.dirname(__FILE__) + "/../log/#{RAILS_ENV}.log","daily")
#end
