#
# Let's fix a few bugs in Webrat!
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
    def scoped_dom
      begin
        @scope.dom.css(@selector).first
      rescue Nokogiri::CSS::SyntaxError => e
        begin
          @scope.dom.xpath(@selector).first
        rescue Nokogiri::XML::XPath::SyntaxError
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
    def test_uploaded_file
      return "" if @original_value.blank?

      case Webrat.configuration.mode
      when :rails
        if content_type
          ActionController::TestUploadedFile.new(@original_value, content_type)
        else
          ActionController::TestUploadedFile.new(@original_value)
        end
      when :rack, :merb
        Rack::Test::UploadedFile.new(@original_value, content_type)
      when :mechanize
        open(@original_value) if @original_value.present?
      end
    end
  end
end

# Basic auth
module Webrat
  class Session
    def basic_auth(user, pass)
      encoded_login = ["#{user}:#{pass}"].pack("m*").gsub(/\n/, '')
      header('HTTP_AUTHORIZATION', "Basic #{encoded_login}")
      if Webrat.adapter_class == MechanizeAdapter
        self.adapter.mechanize.auth(user, pass)
      end
    end
  end
end

# Redirects
module Webrat
  class MechanizeAdapter
    def mechanize
      @mechanize ||= begin
        mechanize = Mechanize.new
        mechanize.redirect_ok = true
        mechanize
      end
    end
  end
end
