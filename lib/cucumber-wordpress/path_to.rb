class WordPress
  def path_to(page_name)
    partial = case page_name
    when /^homepage$/
      '/'
    when /^login page$/
      '/wp-login.php'
    when /^admin dashboard$/
      '/wp-admin/'
    when /^new post$/
      '/wp-admin/post-new.php'
    when /^media library$/
      "/wp-admin/upload.php"
    when /^manage themes$/
      '/wp-admin/themes.php'
    when /^plugins$/
      '/wp-admin/plugins.php'
    when /^new user$/
      '/wp-admin/user-new.php'
    when /^new page$/
      case major
      when 2
        '/wp-admin/page-new.php'
      when 3
        '/wp-admin/post-new.php?post_type=page'
      else
        raise
      end
    when /^(post|page) "(.+?)"$/
      WordPress.php("echo get_permalink(#{get_post_id($2)})")
    when /^edit (post|page) "(.+?)"$/
      "/wp-admin/#{$1}.php?action=edit&post=#{get_post_id($2)}"
    else
      return nil
    end
    URI::join("http://#{@WEBHOST}/", partial).to_s
  end
end
