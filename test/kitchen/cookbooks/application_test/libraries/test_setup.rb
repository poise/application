#
# Cookbook Name:: application_test
# Library:: test_setup
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

require 'fileutils'

def remove_app(app_name)
  app_dir = "#{node['application_test']['root_dir']}/#{app_name}"
  rev_path = "/tmp/vagrant-chef-1/revision-deploys/#{app_name}"

  FileUtils.rm_rf(app_dir)
  FileUtils.rm(rev_path) if File.exists?(rev_path)
end

def test_results(app_name)
  tmp_dir = "/tmp/#{app_name}"

  FileUtils.rm_rf(tmp_dir)
  FileUtils.mkdir_p(tmp_dir)

  tmp_dir
end
