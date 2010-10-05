# encoding: utf-8

#
# All the standard stuff
#

require 'spec/mocks'
require 'webrat'
require 'cucumber-wordpress/webrat-patches'
Webrat.configure do |config|
  config.mode = :mechanize
end
World do
  session = Webrat::Session.new
  session.extend(Webrat::Methods)
  session.extend(Webrat::Matchers)
  session
end

#
# WordPress stuff
#

require 'cucumber-wordpress'
require 'cucumber-wordpress/steps'
WordPress.configure(YAML::load(open(File.join(File.dirname(__FILE__),'config.yml'))))
WordPress.write_config
WordPress.create_db
at_exit do
  WordPress.reset_config
  WordPress.drop_db
end
Before do |scenario|
  WordPress.reset_db
end

#
# And we're done!
#
