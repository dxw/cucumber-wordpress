# encoding: utf-8

Then /^plugin "([^\"]*)" should be (enabled|disabled)$/ do |plugin,able|
  Given 'I am logged in as "admin"'
  Given 'I am on plugins'
  link = %Q&//a[contains(@href,"#{plugin}")]&
  if able == 'enabled'
    text = 'Deactivate'
  else
    text = 'Activate'
  end
  should_see_within "#{link}/..", text
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
