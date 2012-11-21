@file_callbacks
Feature: Run file callbacks

In order to write my application recipe
As a recipe developer
I want my callbacks to be called

  Scenario: Deploy a basic app
    Given a new server
    Then the "/var/www/file_callbacks" directory should exist
    And the "/var/www/file_callbacks/shared" directory should exist
    And the "/var/www/file_callbacks/releases/7cfe06bf4d245264e9d3ec88b54da9d275fe9174" directory should exist
    And the "/tmp/file_callbacks/before_migrate" file should exist
    And it should contain a line matching "release_path /var/www/file_callbacks/releases/7cfe06bf4d245264e9d3ec88b54da9d275fe9174"
    And it should contain a line matching "shared_path /var/www/file_callbacks/shared"
    And the "/tmp/file_callbacks/before_symlink" file should exist
    And it should contain a line matching "release_path /var/www/file_callbacks/releases/7cfe06bf4d245264e9d3ec88b54da9d275fe9174"
    And it should contain a line matching "shared_path /var/www/file_callbacks/shared"
    And the "/tmp/file_callbacks/before_restart" file should exist
    And it should contain a line matching "release_path /var/www/file_callbacks/releases/7cfe06bf4d245264e9d3ec88b54da9d275fe9174"
    And it should contain a line matching "shared_path /var/www/file_callbacks/shared"
    And the "/tmp/file_callbacks/after_restart" file should exist
    And it should contain a line matching "release_path /var/www/file_callbacks/releases/7cfe06bf4d245264e9d3ec88b54da9d275fe9174"
    And it should contain a line matching "shared_path /var/www/file_callbacks/shared"
