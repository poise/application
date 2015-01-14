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

action :before_compile do
  file '/before_compile' do
    content new_resource.content
  end
end

action :before_deploy do
  file '/before_deploy' do
    content new_resource.release_path
  end
end

action :before_migrate do
  file '/before_migrate'
end

action :before_symlink do
  file '/before_symlink'
end

action :before_restart do
  file '/before_restart'
end

action :after_restart do
  file '/after_restart'
end
