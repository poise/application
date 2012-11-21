@basic_app
Feature: Deploy a basic app

In order to run my application
As a developer
I want to deploy a basic application

  Scenario: Deploy a basic app
    Given a new server
    Then the "/var/www/basic_app" directory should exist
    And the "/var/www/basic_app/shared" directory should exist
    And the "/var/www/basic_app/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f" directory should exist
    And it should be owned by nobody with group daemon
    And "/var/www/basic_app/current" should be a symlink to "/var/www/basic_app/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f"
