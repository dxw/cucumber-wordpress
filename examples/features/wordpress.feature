Feature: WordPress example
  WordPress should be as easy to test as Rails

  Background:
    Given WordPress is installed

  Scenario: Submitting a post
    Given I am logged in as "admin"
    And I am on admin dashboard
    When I follow "Add New" within "#menu-posts"
    Then I should see "Add New Post"
    When I fill in "title" with "hullo thar"
    And I fill in "content" with "We all love WordPress."
    And I press "publish"
    Then there should be 1 post
    Given I am on homepage
    Then I should see "hullo thar"
    And I should see "We all love WordPress."
