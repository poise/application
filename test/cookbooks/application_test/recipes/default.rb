#
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

application '/home/app' do
  test_plugin do
    content 'test plugin'
  end
end

# Restart behavior test.
directory '/opt/restarter' do
  owner 'root'
  group 'root'
  mode '755'
end
file '/opt/restarter/main.rb' do
  content <<-EOH
require 'webrick'
server = WEBrick::HTTPServer.new(Port: 2000)
trap('INT') { server.shutdown }
server.mount_proc '/' do |req, res|
  res.body = 'One'
end
server.start
EOH
end
poise_service 'restarter' do
  command '/opt/chef/embedded/bin/ruby /opt/restarter/main.rb'
end

application '/opt/restarter' do
  file '/opt/restarter/main.rb2' do
    path '/opt/restarter/main.rb'
    content <<-EOH
require 'webrick'
server = WEBrick::HTTPServer.new(Port: 2000)
trap('INT') { server.shutdown }
server.mount_proc '/' do |req, res|
  res.body = 'Two'
end
server.start
EOH
  end
  poise_service 'restarter2' do
    service_name 'restarter'
    command '/opt/chef/embedded/bin/ruby /opt/restarter/main.rb'
  end
end
