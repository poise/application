#
# Cookbook Name:: application_test
# Recipe:: block_callbacks
#
# Copyright 2012, ZephirWorks
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

app_name = "block_callbacks"
app_dir = "#{node['application_test']['root_dir']}/#{app_name}"

remove_app(app_name)
tmp_dir = test_results(app_name)

application app_name do
  repository  "https://github.com/h5bp/html5-boilerplate.git"
  revision    "0b60046431d14b6615d53ae6d8bd0ac62ae3eb6f"  # v4.0.0 tag
  path        app_dir
  owner       node['application_test']['owner']
  group       node['application_test']['group']

  #
  # All these hooks should be invoked with the same context
  #
  %w[before_deploy before_migrate before_symlink before_restart after_restart].each do |hook_name|
    send(hook_name) do # invoke the hook by name
      resource = @new_resource

      template "#{tmp_dir}/#{hook_name}" do
        source "hooks.erb"
        mode 0644
        variables(:release_path => resource.release_path,
                  :shared_path  => resource.shared_path)
      end
    end
  end
end
