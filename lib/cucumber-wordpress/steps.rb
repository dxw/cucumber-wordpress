Given /^WordPress is installed$/ do
  visit path_to 'homepage'
  title = 'A Very Boring Test Title'
  if response.include? '<title>WordPress &rsaquo; Installation</title>'
    fill_in('Blog Title', :with => title)
    fill_in('Your E-mail', :with => 'test@example.org')
    click_button('Install WordPress')
    WordPress.passwords = {'admin' => response.match(%r[<td><code>(.+)</code><br />])[1]}
  end
  visit path_to 'login page'
  response.should include "<title>#{title} &rsaquo; Log In</title>"

  # Take this so we can reset the DB before each scenario
  WordPress.original_contents = {}
  %w[comments
   links
   options
   postmeta
   posts
   term_relationships
   term_taxonomy
   terms
   usermeta
   users].each do |table|
    WordPress.original_contents[table] = WordPress.mysql.query("select * from #{WordPress.TABLE_PREFIX}#{table}").map{|row|row}
   end
end

Given /^I am logged in as "([^\"]*)"$/ do |user|
  visit path_to 'login page'
  fill_in('Username', :with => user)
  fill_in('Password', :with => WordPress.passwords[user])
  click_button('Log In')
end

Given /^theme "([^\"]*)" is enabled$/ do |theme|
  Given 'I am logged in as "admin"'
  Given 'I am on manage themes'
  click_link_within %Q&//a[contains(@title,"#{theme}")]/..&, 'Activate'
end

Given /^plugin "([^\"]*)" is (enabled|disabled)$/ do |plugin,able|
  Given 'I am logged in as "admin"'
  visit path_to 'admin dashboard'
  click_link('Plugins')
  link = %Q&//a[contains(@href,"#{plugin}")]&
  if dom.xpath("#{link}/child::text()").any?{|t|t.to_s == 'Activate'}
    if able == 'enabled'
      click_link_within("#{link}/..",'Activate')
    else
      click_link_within("#{link}/..",'Deactivate')
    end
  end
end

Then /^there should be (\d+) posts?$/ do |count|
  WordPress.mysql.query("select count(*) from #{WordPress.TABLE_PREFIX}posts where ID != 1 and post_type = 'post' and post_status != 'trash'").fetch_row.first.to_i.should == count.to_i
end

Then /^there should be (\d+) categories?$/ do |count|
  # Two initial categories, which we won't count: Uncategorized and Blogroll
  WordPress.mysql.query("select count(*) from #{WordPress.TABLE_PREFIX}terms where term_id > 2").fetch_row.first.to_i.should == count.to_i
end

Then /^there should be a category called "([^\"]*)"$/ do |category|
  WordPress.mysql.query("select count(*) > 0 from #{WordPress.TABLE_PREFIX}terms where name = '#{Mysql.escape_string(category)}' or slug = '#{Mysql.escape_string(category)}'").fetch_row.first.to_i.should == 1
end

Then /^there should be a post called "([^\"]*)"$/ do |post|
  WordPress.mysql.query("select count(*) > 0 from #{WordPress.TABLE_PREFIX}posts where post_title = '#{Mysql.escape_string(post)}' or post_name = '#{Mysql.escape_string(post)}'").fetch_row.first.to_i.should == 1
end

Then /^there should be a post called "([^\"]*)" in the "([^\"]*)" category$/ do |post, category|
  WordPress.mysql.query("select count(*) > 0 from #{WordPress.TABLE_PREFIX}terms join #{WordPress.TABLE_PREFIX}term_relationships join #{WordPress.TABLE_PREFIX}posts where term_id = term_taxonomy_id and ID = object_id and (post_title = '#{Mysql.escape_string(post)}' or post_name = '#{Mysql.escape_string(post)}') and (name = '#{Mysql.escape_string(category)}' or slug = '#{Mysql.escape_string(category)}')").fetch_row.first.to_i.should == 1
end

Given /^option "([^\"]*)" is set to "(.*)"$/ do |option, value|
  WordPress.mysql.query(%Q'DELETE FROM #{WordPress.TABLE_PREFIX}options WHERE option_name="#{Mysql.escape_string option}"')
  WordPress.mysql.query(%Q'INSERT INTO #{WordPress.TABLE_PREFIX}options SET option_name="#{Mysql.escape_string option}", option_value="#{Mysql.escape_string value}"')
end
