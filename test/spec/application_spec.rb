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

require 'spec_helper'

describe Chef::Resource::Application do
  step_into(:application)
  recipe do
    application '/home/app' do
      git do
        repository 'https://github.com/poise/test_repo.git'
        revision 'master'
        deploy_key 'secretkey'
      end
    end
  end

  def sync_poise_git(name)
    ChefSpec::Matchers::ResourceMatcher.new(:poise_git, :sync, name)
  end

  it { is_expected.to deploy_application('/home/app') }
  it { is_expected.to sync_poise_git('/home/app').with(repository: 'https://github.com/poise/test_repo.git', revision: 'master', deploy_key: 'secretkey', environment: 'production') }
end
