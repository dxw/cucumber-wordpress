# encoding: utf-8

def see? content
  see_within? '.', content
end

def see_within? selector, content
  within(selector) do |item|
    if item.nil?
      has_content? content
    else
      item.dom.to_s.include? content
    end
  end
end

def should_see_within selector, content
  within(selector) do |item|
    if item.nil?
      page.should have_content content
    else
      item.dom.to_s.should include content
    end
  end
end

require 'cucumber-wordpress/steps/given'
require 'cucumber-wordpress/steps/should'
