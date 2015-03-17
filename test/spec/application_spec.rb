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
      remote_directory do
        source 'myapp'
      end
    end
  end

  before do
    # Unwrap notifying_block
    allow_any_instance_of(Chef::Provider::Application).to receive(:notifying_block) {|&block| block.call }
  end

  def sync_poise_git(name)
    ChefSpec::Matchers::ResourceMatcher.new(:poise_git, :sync, name)
  end

  it { is_expected.to deploy_application('/home/app').with(environment: 'production') }
  it { is_expected.to create_directory('/home/app') }
  it { is_expected.to create_remote_directory('/home/app').with(source: 'myapp') }

  context 'with a plugin application_test_plugin' do
    resource(:application_test_plugin) do
      include Poise(Chef::Resource::Application)
    end
    provider(:application_test_plugin)
    recipe do
      application '/home/app' do
        test_plugin 'plugin'
      end
    end

    it { is_expected.to run_application_test_plugin('plugin') }
  end # /context with a plugin application_test_plugin

  context 'with a plugin test_plugin' do
    resource(:test_plugin) do
      include Poise(Chef::Resource::Application)
    end
    provider(:test_plugin)
    recipe do
      application '/home/app' do
        test_plugin 'plugin'
      end
    end

    it { is_expected.to run_test_plugin('plugin') }
  end # /context with a plugin test_plugin

  context 'with a plugin appication_test_test_plugin' do
    resource(:application_test_test_plugin) do
      include Poise(Chef::Resource::Application)
    end
    provider(:application_test_test_plugin)
    recipe do
      extend RSpec::Mocks::ExampleMethods
      allow(run_context.cookbook_collection).to receive(:each).and_yield('application_test', double())
      application '/home/app' do
        test_plugin 'plugin'
      end
    end

    it { is_expected.to run_application_test_test_plugin('plugin') }
  end # /context with a plugin application_test_test_plugin

  context 'with a plugin that has no name' do
    resource(:test_plugin) do
      include Poise(Chef::Resource::Application)
    end
    provider(:test_plugin)
    recipe do
      application '/home/app' do
        test_plugin
      end
    end

    it { is_expected.to run_test_plugin('/home/app') }
  end # /context with a plugin that has no name

end
