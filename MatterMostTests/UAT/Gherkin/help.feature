Feature: It can respond to help messages

Background: Login to Mattermost
    Given mattermost server http://localhost:8065
    And mattermost user 'user2@example.com' with passsword 'Password1'

Scenario: Sending a valid help message
    When sending a message of ! help
    And waiting 2 seconds
    Then the message should have a reaction of white_check_mark
    And poshbot returns a message that starts with ```````nFullCommandName

Scenario: Sending a help message with an unknown command
    When sending a message of ! help commanddoesntexist
    And waiting 2 seconds
    Then the message should have a reaction of white_check_mark
    And poshbot returns a message that contains No commands found matching \[commanddoesntexist\]

Scenario: Sending an invalid help message
    When sending a message of ! help some random text which should error
    And waiting 2 seconds
    Then the message should have a reaction of exclamation
    And poshbot returns a message that contains Command Exception
