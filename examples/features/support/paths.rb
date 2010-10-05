# encoding: utf-8

require 'cucumber-wordpress'

module NavigationHelpers
  def path_to(page_name)

    # Default WordPress paths
    path = WordPress.path_to(page_name)
    return path unless path.nil?

    # Our own paths
    partial = case page_name
    when /^my special page$/
      '/my-special-page.php'
    else
      raise "Can't find mapping from \"#{page_name}\" to a path.\n"
    end
    URI::join("http://#{WordPress.WEBHOST}/", partial)
  end
end

World(NavigationHelpers)
