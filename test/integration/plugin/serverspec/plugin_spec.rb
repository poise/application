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

require 'serverspec'
set :backend, :exec

describe file('/before_compile') do
  it { is_expected.to be_a_file }
  its(:content) { is_expected.to eq 'test plugin' }
end

describe file('/before_deploy') do
  it { is_expected.to be_a_file }
  its(:content) { is_expected.to start_with '/home/app/releases/' }
end

describe file('/before_migrate') do
  it { is_expected.to be_a_file }
end

describe file('/before_symlink') do
  it { is_expected.to be_a_file }
end

describe file('/before_restart') do
  it { is_expected.to be_a_file }
end

describe file('/after_restart') do
  it { is_expected.to be_a_file }
end
