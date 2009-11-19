#
# All the standard stuff
#

require 'spec/mocks'
require 'webrat'
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
# Apart from a couple of patches we need to apply to webrat...
#

# For some reason the MechanizeAdapter uses response_body instead of response.body.
# This is needed
module Webrat
  class Session
    include Spec::Mocks::ExampleMethods
    def response
      m = mock
      m.should_receive(:body).any_number_of_times.and_return(response_body)
      m
    end
  end
end

# Use XPath in click_link_within, etc.
# This is needed too
module Webrat
  class Scope
    protected

    def xpath_scoped_dom
      Webrat::XML.xpath_at(@scope.dom, @selector)
    end

    def scoped_dom
      begin
        Webrat::XML.css_at(@scope.dom, @selector)
      rescue Nokogiri::CSS::SyntaxError, Nokogiri::XML::XPath::SyntaxError => e
        begin
          # That was not a css selector, mayby it's an xpath selector?
          xpath_scoped_dom
        rescue
          # Raise original css syntax error if selector is not xpath either
          raise e
        end
      end
    end
  end
end

# Fix attach_file so it works with mechanize
# Thanks: https://webrat.lighthouseapp.com/projects/10503/tickets/303-tiny-patch-for-attach_file-to-work-with-mechanize
# This is not needed for cucumber-wordpress (yet)
module Webrat
  class FileField < Field
  protected
    def test_uploaded_file
      open(@value)
    end
  end
end
