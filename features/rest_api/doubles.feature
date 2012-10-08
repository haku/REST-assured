Feature: use doubles via api
  In order to use double data in integration tests
  As a developer
  I want to mock rest services my app is consuming from

  Scenario Outline: create double
    When I create a double with "<fullpath>" as fullpath, "<content>" as response content, "<verb>" as request verb and status as "<status>"
    Then there should be 1 double with "<fullpath>" as fullpath, "<content>" as response content, "<result_verb>" as request verb and status as "<result_status>"

    Examples:
      | fullpath           | content      | verb   | result_verb | status | result_status |
      | /api/something     | created      | POST   | POST        | 200    | 200           |
      | /api/sss           | changed      | PUT    | PUT         | 201    | 201           |
      | /api/asdfsf        | removed      | DELETE | DELETE      | 300    | 300           |
      | /api/some          | text content | GET    | GET         | 303    | 303           |
      | /api/some?a=3&b=dd | more content |        | GET         |        | 200           |
      | /api/empty         |              | POST   | POST        |        | 200           |
      | /api/file          |              | HEAD   | HEAD        |        | 200           |
      | /api/file          |              | PATCH  | PATCH       |        | 200           |

  Scenario: view created double details
    When I create a double
    Then I should be able to get json representation of that double from response

  Scenario Outline: request fullpath that matches double
    Given there is double with "<fullpath>" as fullpath, "<content>" as response content, "<verb>" as request verb and "<status>" as status
    When I "<verb>" "<fullpath>"
    Then I should get "<status>" as response status and "<content>" in response content

    Examples:
      | fullpath           | content      | verb   | status |
      | /api/something     | created      | POST   | 200    |
      | /api/sss           | changed      | PUT    | 201    |
      | /api/asdfsf        | removed      | DELETE | 202    |
      | /api/some?a=3&b=dd | more content | GET    | 203    |
      | /other/api         |              | GET    | 303    |

  # current rule: last added double gets picked
  Scenario Outline: request fullpath that matches multiple doubles
    Given there is double with "<fullpath>" as fullpath and "<content>" as response content
    And there is double with "<fullpath>" as fullpath and "<content2>" as response content
    When I "GET" "<fullpath>"
    Then I should get "<content2>" in response content

    Examples:
      | fullpath           | content      | content2        |
      | /api/something     | test content | another content |
      | /api/some?a=3&b=dd | more content | some text       |

  Scenario: request fullpath that does not match any double
    Given there are no doubles
    When I "GET" "/api/something"
    Then I should get 404 in response status

  Scenario: clear doubles
    Given there are some doubles
    When I delete all doubles
    Then there should be no doubles

  @templates
  Scenario: content not touched if template_type not set
    Given there is double with "/api/something" as fullpath and "content:::request_count" as response content
    When I "GET" "/api/something"
    Then I should get "content:::request_count" in response content

  @templates
  Scenario: request count incremented and inserted into content when using custom templates
    Given there is double with "/api/something" as fullpath, "content:::request_count" as response content and "custom" as template_type
    When I "GET" "/api/something"
    Then I should get "content1" in response content
    When I "GET" "/api/something"
    Then I should get "content2" in response content
    When I "GET" "/api/something"
    Then I should get "content3" in response content

  @templates
  Scenario: request count incremented and inserted into content when using erubis templates
    Given there is double with "/api/something" as fullpath, "content<%= double.request_count %>" as response content and "erubis" as template_type
     When I "GET" "/api/something"
    Then I should get "content1" in response content
    When I "GET" "/api/something"
    Then I should get "content2" in response content
    When I "GET" "/api/something"
    Then I should get "content3" in response content

  @templates
  Scenario: request can trigger creation of other doubles
    Given there is double with "/api/something" as fullpath, "<% double_dao.create(:fullpath => '/api/other', :content => 'other content') %>content" as response content and "erubis" as template_type
    When I "GET" "/api/something"
    Then I should get "content" in response content
    When I "GET" "/api/other"
    Then I should get "other content" in response content
