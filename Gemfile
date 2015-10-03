#
# Copyright 2009-2015, Opscode, Inc.
# Copyright 2015, Noah Kantrowitz
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

source 'https://rubygems.org/'

gemspec path: File.expand_path('..', __FILE__)

def dev_gem(name, path: File.join('..', name), github: nil)
  path = File.expand_path(File.join('..', path), __FILE__)
  if File.exist?(path)
    gem name, path: path
  elsif github
    gem name, github: github
  end
end

dev_gem 'halite'
dev_gem 'poise'
dev_gem 'poise-boiler'
dev_gem 'poise-service'
