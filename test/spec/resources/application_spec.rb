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
require 'poise'

class ApplicationTestRealClass < Chef::Resource
  include Poise
  provides(:application_test_other_name)
  actions(:run)
end

describe PoiseApplication::Resources::Application::Resource do
  step_into(:application)
  recipe do
    application '/home/app' do
      remote_directory do
        source 'myapp'
      end
    end
  end

  it { is_expected.to deploy_application('/home/app').with(environment: {}) }
  it { is_expected.to create_directory('/home/app') }
  it { is_expected.to create_remote_directory('/home/app').with(source: 'myapp') }

  context 'with a plugin application_test_plugin' do
    resource(:application_test_plugin) do
      include Poise(parent: :application)
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
      include Poise(parent: :application)
    end
    provider(:test_plugin)
    recipe do
      application '/home/app' do
        test_plugin 'plugin'
      end
    end

    it { is_expected.to run_test_plugin('plugin') }
  end # /context with a plugin test_plugin

  context 'with a plugin application_test_test_plugin' do
    resource(:application_test_test_plugin) do
      include Poise(parent: :application)
    end
    provider(:application_test_test_plugin)
    recipe do
      extend RSpec::Mocks::ExampleMethods
      allow(run_context.cookbook_collection).to receive(:keys).and_return(%w{application_test})
      application '/home/app' do
        test_test_plugin 'plugin'
      end
    end

    it { is_expected.to run_application_test_test_plugin('plugin') }
  end # /context with a plugin application_test_test_plugin

  context 'with an LWRP application_test_test_plugin' do
    resource(:application_test_test_plugin, parent: Chef::Resource::LWRPBase) do
      include Poise(parent: :application)
    end
    provider(:application_test_test_plugin)
    recipe do
      extend RSpec::Mocks::ExampleMethods
      allow(run_context.cookbook_collection).to receive(:keys).and_return(%w{application_test})
      application '/home/app' do
        test_plugin 'plugin'
      end
    end

    it { is_expected.to run_application_test_test_plugin('plugin') }
  end # /context with an LWRP application_test_test_plugin

  context 'with a plugin that has no name' do
    resource(:test_plugin) do
      include Poise(parent: :application)
    end
    provider(:test_plugin)
    recipe do
      application '/home/app' do
        test_plugin
      end
    end

    it { is_expected.to run_test_plugin('/home/app') }
  end # /context with a plugin that has no name

  context 'with a resource that does not match the class name' do
    recipe do
      application '/home/app' do
        test_other_name
      end
    end

    it { is_expected.to run_application_test_other_name('/home/app') }
  end # /context with a resource that does not match the class name

  context 'with a subresource that has an update' do
    step_into(:application)
    step_into(:ruby_block)
    resource(:test_plugin) do
      include Poise(parent: :application)
      actions(:run, :restart)
    end
    provider(:test_plugin) do
      def action_restart
        node.run_state['did_restart'] = true
      end
    end
    recipe do
      application '/home/app' do
        ruby_block { block {} }
        test_plugin
      end
    end

    it { is_expected.to run_ruby_block('/home/app') }
    it { expect(chef_run.ruby_block('/home/app').updated?).to be true }
    it { is_expected.to run_test_plugin('/home/app') }
    it { expect(chef_run.node.run_state['did_restart']).to be true }
  end # /context with a subresource that has an update
end
