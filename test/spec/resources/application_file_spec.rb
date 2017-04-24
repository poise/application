#
# Copyright 2015-2016, Noah Kantrowitz
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

describe PoiseApplication::Resources::ApplicationFile do
  context 'with a relative path' do
    recipe do
      application '/home/app' do
        file 'app.conf'
      end
    end

    it { is_expected.to create_application_file('app.conf').with(path: '/home/app/app.conf') }
  end # /context with a relative path

  context 'with an absolute path' do
    recipe do
      application '/home/app' do
        file '/app.conf'
      end
    end

    it { is_expected.to create_application_file('/app.conf').with(path: '/app.conf') }
  end # /context with an absolute path

  context 'with an application user' do
    recipe do
      application '/home/app' do
        owner 'myuser'
        file 'app.conf'
      end
    end

    it { is_expected.to create_application_file('app.conf').with(owner: 'myuser') }
  end # /context 'with an application user

  context 'with an application user and a local user' do
    recipe do
      application '/home/app' do
        owner 'myuser'
        file 'app.conf' do
          owner 'otheruser'
        end
      end
    end

    it { is_expected.to create_application_file('app.conf').with(owner: 'otheruser') }
  end # /context 'with an application user and a local user

  context 'with an application group' do
    recipe do
      application '/home/app' do
        group 'mygroup'
        file 'app.conf'
      end
    end

    it { is_expected.to create_application_file('app.conf').with(group: 'mygroup') }
  end # /context 'with an application group

  context 'with an application user and a local group' do
    recipe do
      application '/home/app' do
        group 'mygroup'
        file 'app.conf' do
          group 'othergroup'
        end
      end
    end

    it { is_expected.to create_application_file('app.conf').with(group: 'othergroup') }
  end # /context 'with an application group and a local group

  context 'with more properties' do
    recipe do
      application '/home/app' do
        file 'app.conf' do
          action :create_if_missing
          content 'teapot'
        end
      end
    end

    it { is_expected.to create_if_missing_application_file('app.conf').with(content: 'teapot')}
  end # /context with more properties
end
