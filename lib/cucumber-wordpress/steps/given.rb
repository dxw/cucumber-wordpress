# encoding: utf-8

Given /^WordPress is installed$/ do
  visit path_to 'homepage'
  title = 'A Very Boring Test Title'

  username = 'admin'
  password = 'password'

  if see_within?('//title', 'WordPress › Installation')
    if see? 'Blog Title'
      # WordPress 2
      fill_in('Blog Title', :with => title)
      fill_in('Your E-mail', :with => 'test@example.org')
      uncheck('blog_public')
      click_button('Install WordPress')

      xpath = '/html/body/table/tr/th[text()="%s"]/../td/code/text()'
      password = response.root.xpath(xpath % 'Password').to_s


    elsif see? 'Site Title'
      # WordPress 3
      fill_in('Site Title', :with => title)

      fill_in('user_name', :with => username)
      # webrat puts values into blank fields, so set these manually
      fill_in('admin_password', :with => password)
      fill_in('admin_password2', :with => password)

      fill_in('Your E-mail', :with => 'test@example.org')
      uncheck('blog_public')
      click_button('Install WordPress')

    else
      raise Exception, 'This version of WordPress is probably not supported'
    end

    WordPress.passwords = {username => password}

  end

  visit path_to 'login page'
  should_see_within('//title', "#{title} › Log In")

  # Take this so we can reset the DB before each scenario
  WordPress.original_contents = {}
   WordPress.tables.each do |table|
     WordPress.original_contents[table] = WordPress.mysql.query("select * from #{table}").map{|row|row}
   end
end

Given /^I am logged in as "([^\"]*)"$/ do |user|
  visit path_to 'login page'

  if respond_to? :find_field
    # This always fails for some unknown reason
    until find_field('user_login').value == user
      fill_in('user_login', :with => user)
    end
  else
    fill_in('user_login', :with => user)
  end

  fill_in('user_pass', :with => WordPress.passwords[user])
  click_button('Log In')
end

Given /^I am not logged in$/ do
  visit path_to 'admin dashboard'
  click_link('Log Out')
end

Given /^theme "([^\"]*)" is enabled$/ do |theme|
  Given 'I am logged in as "admin"'
  Given 'I am on manage themes'
  click_link_within %Q&//a[contains(@title,"#{theme}")]/..&, 'Activate'
end

Given /^plugin "([^\"]*)" is (enabled|disabled)$/ do |plugin,able|
  Given 'I am logged in as "admin"'
  Given 'I am on plugins'
  link = %Q&//a[contains(@href,"plugin=#{plugin}%2F")]&
  if able == 'enabled'
    text = 'Activate'
  else
    text = 'Deactivate'
  end
  click_link_within "#{link}/..", text
end

Given /^there is a (post|page) called "([^\"]*)"$/ do |post_type,title|
  visit path_to "new #{post_type}"
  case WordPress.major
  when 2
    fill_in 'title', :with => title
  when 3
    fill_in 'post_title', :with => title
  end
  click_button 'Publish'
end

Given /^the (post|page) "([^\"]*)" has meta "([^\"]*)" as "(.*)"$/ do |post_type,title,key,value|
  WordPress.mysql.query(%Q'INSERT INTO #{WordPress.TABLE_PREFIX}postmeta SET post_id=(SELECT ID FROM #{WordPress.TABLE_PREFIX}posts WHERE post_title="#{title}" AND post_type != "revision"), meta_key="#{Mysql.escape_string(key)}", meta_value="#{Mysql.escape_string(value)}"')
end

Given /^the page "([^\"]*)" has template "([^\"]*)"$/ do |title,template|
  visit path_to %Q%edit page "#{title}"%
  select template, :from => 'Page Template'
  click_button 'Update'
end

Given /^permalinks are set as "([^\"]*)"$/ do |structure|
  visit '/wp-admin/options-permalink.php'
  fill_in 'permalink_structure', :with => structure
  click_button 'Save Changes'
end

Given /^option "([^\"]*)" is set to "(.*)"$/ do |option, value|
  WordPress.mysql.query(%Q'DELETE FROM #{WordPress.TABLE_PREFIX}options WHERE option_name="#{Mysql.escape_string option}"')
  WordPress.mysql.query(%Q'INSERT INTO #{WordPress.TABLE_PREFIX}options SET option_name="#{Mysql.escape_string option}", option_value="#{Mysql.escape_string value}"')
end

Given /^there is a user "([^"]*)" with role "([^"]*)"$/ do |username, role|
  password = username

  visit path_to 'new user'

  fill_in 'user_login', :with => username
  fill_in 'email', :with => username+'@example.org'
  fill_in 'pass1', :with => password
  fill_in 'pass2', :with => password
  select role.capitalize, :from => 'role'
  begin
    click_button 'Add New User' # 3.1
  rescue Webrat::NotFoundError
    click_button 'Add User' # 3.0
  end

  WordPress.passwords.merge!({username => password})
end
