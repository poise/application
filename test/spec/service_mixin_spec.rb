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

describe PoiseApplication::ServiceMixin do
  resource(:mixin_test) do
    include described_class
  end
  provider(:mixin_test) do
    include described_class
  end
  let(:service_resource) { subject.mixin_test('/srv/mixintest').provider_for_action(:enable).send(:service_resource) }

  context 'with an application parent' do
    recipe do
      application '/srv/mixintest' do
        owner 'myuser'
        mixin_test
      end
    end

    it { is_expected.to enable_mixin_test('/srv/mixintest').with(service_name: 'mixintest', user: 'myuser') }
    it { expect(service_resource.service_name).to eq 'mixintest' }
    it { expect(service_resource.user).to eq 'myuser' }
    it { expect(service_resource.directory).to eq '/srv/mixintest' }
    it { expect(service_resource.environment).to eq({}) }

    context 'with app_state environment data' do
      resource(:state_test) do
        include Poise(parent: :application)
      end
      provider(:state_test) do
        def action_run
          new_resource.parent.app_state[:environment] = {'ENVKEY' => 'envvalue'}
        end
      end
      recipe do
        application '/srv/mixintest' do
          state_test
          mixin_test
        end
      end

      it { is_expected.to enable_mixin_test('/srv/mixintest').with(service_name: 'mixintest') }
      it { expect(service_resource.service_name).to eq 'mixintest' }
      it { expect(service_resource.directory).to eq '/srv/mixintest' }
      it { expect(service_resource.environment).to eq({'ENVKEY' => 'envvalue'}) }
    end # /context with app_state environment data
  end # /context with an application parent

  context 'without an application parent' do
    recipe do
      mixin_test '/srv/mixintest'
    end

    it { is_expected.to enable_mixin_test('/srv/mixintest').with(service_name: 'mixintest', user: 'root') }
    it { expect(service_resource.service_name).to eq 'mixintest' }
    it { expect(service_resource.user).to eq 'root' }
    it { expect(service_resource.directory).to eq '/srv/mixintest' }
    it { expect(service_resource.environment).to eq({}) }
  end # /context withput an application parent
end
