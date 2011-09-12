Feature: use fixtures via api
  In order to use fixture data in integration tests
  As a developer
  I want to mock rest services my app is consuming from

  Scenario Outline: create fixture
    When I create a fixture with "<fullpath>" as fullpath, "<content>" as response content and "<method>" as request method
    Then there should be 1 fixture with "<fullpath>" as fullpath, "<content>" as response content and "<result_method>" as request method

    Examples:
      | fullpath           | content      | method | result_method |
      | /api/something     | created      | POST   | POST          |
      | /api/sss           | changed      | PUT    | PUT           |
      | /api/asdfsf        | removed      | DELETE | DELETE        |
      | /api/some          | text content | GET    | GET           |
      | /api/some?a=3&b=dd | more content |        | GET           |

  Scenario Outline: request fullpath that matches fixture
    Given there is fixture with "<fullpath>" as fullpath, "<content>" as response content and "<method>" as request method
    When I "<method>" "<fullpath>"
    Then I should get "<content>" in response content

    Examples:
      | fullpath           | content      | method |
      | /api/something     | created      | POST   |
      | /api/sss           | changed      | PUT    |
      | /api/asdfsf        | removed      | DELETE |
      | /api/some?a=3&b=dd | more content | GET    |

  # current rule: last added fixture gets picked
  Scenario Outline: request fullpath that matches multiple fixtures
    Given there is fixture with "<fullpath>" as fullpath and "<content>" as response content
    And there is fixture with "<fullpath>" as fullpath and "<content2>" as response content
    When I "GET" "<fullpath>"
    Then I should get "<content2>" in response content

    Examples:
      | fullpath           | content      | content2        |
      | /api/something     | test content | another content |
      | /api/some?a=3&b=dd | more content | some text       |

  Scenario: request fullpath that does not match any fixture
    Given there are no fixtures
    When I "GET" "/api/something"
    Then I should get 404 in response status

  Scenario: clear fixtures
    Given there are some fixtures
    When I delete all fixtures
    Then there should be no fixtures
