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
  owner 'root'
  group 'root'

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
* `application_javascript` – *Coming soon!*
* `application_java` – *Coming soon!*
* `application_go` – *Coming soon!*
* `application_erlang` – *Coming soon!*

## Sponsors

Development sponsored by [Chef Software](https://www.chef.io/), [Symonds & Son](http://symondsandson.com/), and [Orion](https://www.orionlabs.co/).

The Poise test server infrastructure is sponsored by [Rackspace](https://rackspace.com/).

## License

Copyright 2015, Noah Kantrowitz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
