maintainer       "Opscode, Inc."
maintainer_email "cookbooks@opscode.com"
license          "Apache 2.0"
description      "Basic infrastructure for deploying a variety of applications"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "1.0.0"

suggests "application_java"
suggests "application_nginx"
suggests "application_php"
suggests "application_python"
suggests "application_ruby"
