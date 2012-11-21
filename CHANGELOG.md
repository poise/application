## v2.0.0:

This release is incompatible with previous releases (hence major
version change). The recipes used in older versions are deprecated and
completely removed. See README.md for further detail.

* [COOK-1673] - Deploy_revision in the application cookbook gives an
  argument error
* [COOK-1820] - Application cookbook: remove deprecated recipes

## v1.0.4:

* [COOK-1567] - Add git submodules to application cookbook

## v1.0.2:

* [COOK-1312] - string callbacks fail with method not found (really
  included this time)
* [COOK-1332] - add `release_path` and `shared_path` methods
* [COOK-1333] - add example for running migrations
* [COOK-1360] - fix minor typos in README
* [COOK-1374] - use runit attributes in unicorn run script

## v1.0.0:

This release introduces the LWRP for application deployment, as well
as other improvements. The recipes will be deprecated in August 2012
as indicated by their warning messages and in the README.md.

* [COOK-634] - Implement LWRP for application deployment
* [COOK-1116] - use other SCMs than git
* [COOK-1252] - add :force_deploy that maps to corresponding action of
  deploy resource
* [COOK-1253] - fix rollback error
* [COOK-1312] - string callbacks fail with method not found
* [COOK-1313] - implicit file based hooks aren't invoked
* [COOK-1318] - Create to_ary method to resolve issue in resources()
  lookup on "application[foo]" resources

## v0.99.14:

* [COOK-1065] - use pip in virtualenv during deploy

## v0.99.12:

* [COOK-606] application cookbook deployment recipes should use ipaddress instead of fqdn

## v0.99.11:

* make the _default chef_environment look like production rails env

## v0.99.10:

* Use Chef 0.10's `node.chef_environment` instead of `node['app_environment']`.
