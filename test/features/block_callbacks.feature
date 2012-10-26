@block_callbacks
Feature: Run block callbacks

In order to write my application recipe
As a recipe developer
I want my callbacks to be called

  Scenario: Deploy a basic app
    Given a new server
    Then the "/var/www/block_callbacks" directory should exist
    And the "/var/www/block_callbacks/shared" directory should exist
    And the "/var/www/block_callbacks/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f" directory should exist
    And the "/tmp/block_callbacks/before_deploy" file should exist
    And it should contain a line matching "release_path /var/www/block_callbacks/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f"
    And it should contain a line matching "shared_path /var/www/block_callbacks/shared"
    And the "/tmp/block_callbacks/before_migrate" file should exist
    And it should contain a line matching "release_path /var/www/block_callbacks/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f"
    And it should contain a line matching "shared_path /var/www/block_callbacks/shared"
    And the "/tmp/block_callbacks/before_symlink" file should exist
    And it should contain a line matching "release_path /var/www/block_callbacks/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f"
    And it should contain a line matching "shared_path /var/www/block_callbacks/shared"
    And the "/tmp/block_callbacks/before_restart" file should exist
    And it should contain a line matching "release_path /var/www/block_callbacks/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f"
    And it should contain a line matching "shared_path /var/www/block_callbacks/shared"
    And the "/tmp/block_callbacks/after_restart" file should exist
    And it should contain a line matching "release_path /var/www/block_callbacks/releases/0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f"
    And it should contain a line matching "shared_path /var/www/block_callbacks/shared"
