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

describe PoiseApplication::AppMixin do
  describe '#app_state_environment' do
    resource(:mixin_test) do
      include described_class
    end
    provider(:mixin_test) do
      include described_class
      def action_run
        new_resource.app_state_environment[:key] = new_resource.name
      end
    end
    recipe do
      application '/srv/mixintest' do
        mixin_test 'one'
        mixin_test 'two'
      end
    end

    it { is_expected.to deploy_application('/srv/mixintest').with(app_state: {'environment' => {'key' => 'two'}}) }

    context 'with no parent' do
      recipe do
        mixin_test 'one'
        mixin_test 'two'
      end

      it { is_expected.to run_mixin_test('one').with(app_state: {'environment' => {'key' => 'one'}}) }
      it { is_expected.to run_mixin_test('two').with(app_state: {'environment' => {'key' => 'two'}}) }
    end # /context with no parent
  end # /describe #app_state_environment
end
