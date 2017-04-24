# Application cookbook

[![Build Status](https://img.shields.io/travis/poise/application.svg)](https://travis-ci.org/poise/application)
[![Gem Version](https://img.shields.io/gem/v/poise-application.svg)](https://rubygems.org/gems/poise-application)
[![Cookbook Version](https://img.shields.io/cookbook/v/application.svg)](https://supermarket.chef.io/cookbooks/application)
[![Coverage](https://img.shields.io/codeclimate/coverage/github/poise/application.svg)](https://codeclimate.com/github/poise/application)
[![Gemnasium](https://img.shields.io/gemnasium/poise/application.svg)](https://gemnasium.com/poise/application)
[![License](https://img.shields.io/badge/license-Apache_2-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

A [Chef](https://www.chef.io/) cookbook to deploy applications.

## Getting Started

The application cookbook provides a central framework to deploy applications
using Chef. Generally this will be web applications using things like Rails,
Django, or NodeJS, but the framework makes no specific assumptions. The core
`application` resource provides DSL support and helpers, but the heavy lifting
is all done in specific plugins detailed below. Each deployment starts with
an `application` resource:

```ruby
application '/path/to/deploy' do
  owner 'root'
  group 'root'

  # ...
end
```

The `application` resource uses the Poise subresource system for plugins. This
means you configure the steps of the deployment like normal recipe code inside
the `application` resource, with a few special additions:

```ruby
application '/path/to/deploy' do
  # Application resource properties.
  owner 'root'
  group 'root'

  # Subresources, like normal recipe code.
  package 'ruby'
  git '/path/to/deploy' do
    repository 'https://github.com/example/myapp.git'
  end
  application_rails '/path/to/deploy' do
    database 'mysql://dbhost/myapp'
  end
end
```

When evaluating the recipe inside the `application` resource, it first checks
for `application_#{resource}`, as well as looking for an LWRP of the same name
in any cookbook starting with `application_`. This means that a resource named
`application_foo` can be used as `foo` inside the `application` resource:

```ruby
application '/path/to/deploy' do
  owner 'root'
  group 'root'

  rails '/path/to/deploy' do
    database 'mysql://dbhost/myapp'
  end
end
```

Additionally if a resource inside the `application` block doesn't have a name,
it uses the same name as the application resource itself:

```ruby
application '/path/to/deploy' do
  owner 'root'
  group 'root'

  rails do
    database 'mysql://dbhost/myapp'
  end
end
```

Other than those two special features, the recipe code inside the `application`
resource is processed just like any other recipe.

## Available Plugins

* [`application_git`](https://github.com/poise/application_git) – Deploy
  application code from a git repository.
* [`application_ruby`](https://github.com/poise/application_ruby) – Manage Ruby
  deployments, such as Rails or Sinatra applications.
* [`application_python`](https://github.com/poise/application_python) – Manage
  Python deployments, such as Django or Flask applications.
* [`application_javascript`](https://github.com/poise/application_javascript) –
  Manage server-side JavaScript deployments using Node.js or io.js.
* `application_java` – *Coming soon!*
* `application_go` – *Coming soon!*
* `application_erlang` – *Coming soon!*

## Requirements

Chef 12 or newer is required.

## Resources

### `application`

The `application` resource has top-level configuration properties for each
deployment and acts as a container for other deployment plugin resources.

```ruby
application '/opt/test_sinatra' do
  git 'https://github.com/example/my_sinatra_app.git'
  bundle_install do
    deployment true
  end
  unicorn do
    port 9000
  end
end
```

#### Actions

* `:deploy` – Deploy the application. *(default)*
* `:start` - Run `:start` on all subresources that support it.
* `:stop` - Run `:stop` on all subresources that support it.
* `:restart` - Run `:restart` on all subresources that support it.
* `:reload` - Run `:reload` on all subresources that support it.

#### Properties

* `path` – Path to deploy the application to. *(name attribute)*
* `environment` – Environment variables for all application deployment steps.
* `group` – System group to deploy the application as.
* `owner` – System user to deploy the application as.
* `action_on_update` – Action to run on the application resource when any
  subresource is updated. *(default: restart)*
* `action_on_update_immediately` – Run the `action_on_update` notification with
  `:immediately`. *(default: false)*

### `application_cookbook_file`, `application_directory`, `application_file`, `application_template`

The `application_cookbook_file`, `application_directory`, `application_file`, and `application_template`
resources extend the core Chef resources to take some application-level
configuration in to account:

```ruby
application '/opt/myapp' do
  template 'myapp.conf' do
    source 'myapp.conf.erb'
  end
  directory 'logs'
end
```

If the resource name is a relative path, it will be expanded relative to the
application path. If an owner or group is declared for the application, those
will be the default user and group for the resource.

All other actions and properties are the same as the similar resource in core Chef.

## Examples

Some test recipes are available as examples for common application frameworks:

* [Sinatra](https://github.com/poise/application_ruby/blob/master/test/cookbooks/application_ruby_test/recipes/sinatra.rb)
* [Rails](https://github.com/poise/application_ruby/blob/master/test/cookbooks/application_ruby_test/recipes/rails.rb)
* [Flask](https://github.com/poise/application_python/blob/master/test/cookbook/recipes/flask.rb)
* [Django](https://github.com/poise/application_python/blob/master/test/cookbook/recipes/django.rb)
* [Express](https://github.com/poise/application_javascript/blob/master/test/cookbook/recipes/express.rb)

## Upgrading From 4.x

While the overall design of the revamped application resource is similar to the
4.x version, some changes will need to be made. The `name` property no longer
exists, with the name attribute being used as the path to the deployment.
The `packages` property has been removed as this is more easily handled via
normal recipe code.

The SCM-related properties like `repository` and `revision` are now handled by
normal plugins. If you were deploying from a private git repository you will
likely want to use the `application_git` cookbook, otherwise just use the
built-in `git` or `svn` resources as per normal.

The properties related to the `deploy` resource like `strategy` and `symlinks`
have been removed. The `deploy` resource is no longer used so these aren't
relevant. As a side effect of this, you'll likely want to point the upgraded
deployment at a new folder or manually clean the `current` and `shared` folders
from the existing folder. The pseudo-Capistrano layout used by the `deploy`
resource has few benefits in a config-managed world and introduced a lot of
complexity and moving pieces that are no longer required.

With the removal of the `deploy` resource, the callback properties and commands
are no longer used as well. Subresources no longer use the complex
actions-as-callbacks arrangement as existed before, instead following normal
Chef recipe flow. Individual subresources may need to be tweaked to work with
newer versions of the cookbooks they come from, though most have stayed similar
in overall approach.

## Database Migrations and Chef

Several of the web application deployment plugins include optional support to
run database migrations from Chef. For "toy" applications where the app and
database run together on a single machine, this is fine and is a nice time
saver. For anything more complex I highly recommend not running database
migrations from Chef. Some initial operations like creating the database and/or
database user are more reasonable as they tend to be done only once and by their
nature the application does not yet have users so some level of eventual
consistency is more acceptable. With migrations on a production application, I
encourage using Chef and the application cookbooks to handle deploying the code
and writing configuration files, but use something more specific to run the
actual migration task. [Fabric](http://www.fabfile.org/),
[Capistrano](http://capistranorb.com/), and [Rundeck](http://rundeck.org/) are
all good choices for this orchestration tooling.

Migrations can generally be applied idempotently but they have unique
constraints (pun definitely intended) that make them tricky in a Chef-like,
convergence-based system. First and foremost is that many table alterations
lock the table for updating for at least some period of time. That can mean that
while staging the new code or configuration data can happen within a window, the
migration itself needs to be run in careful lockstep with the rest of the
deployment process (eg. moving things in and out of load balancers). Beyond
that, while most web frameworks have internal idempotence checks for migrations,
running the process on two servers at the same time can have unexpected effects.

Overall migrations are best thought of as a procedural step rather than a
declaratively modeled piece of the system.

## Application Signals and Updates

The `application` resource exposes `start`, `stop`, `restart`, and `reload`
actions which will dispatch to any subresources attached to the application.
This allows for generic application-level restart or reload signals that will
work with any type of deployment.

Additionally the `action_on_update` property is used to set a default
notification so any subresource that updates will trigger an application
restart or reload. This can be disabled by setting `action_on_update false` if
you want to take manual control of service restarts.

## Sponsors

Development sponsored by [Chef Software](https://www.chef.io/), [Symonds & Son](http://symondsandson.com/), and [Orion](https://www.orionlabs.co/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2015-2016, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
