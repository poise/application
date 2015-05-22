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

describe PoiseApplication::Utils do
  describe '.primary_group_for' do
    let(:user) { nil }
    let(:fake_user) { double('fake user', gid: 123, to_s: user) }
    let(:fake_group) { double('fake group', name: 'mygroup' )}
    subject { described_class.primary_group_for(user) }
    before do
      allow(Etc).to receive(:endpwent)
      allow(Etc).to receive(:endgrent)
    end

    context 'with an integer' do
      let(:user) { 1 }
      it do
        expect(Etc).to receive(:getpwuid).with(1).and_return(fake_user)
        expect(Etc).to receive(:getgrgid).with(123).and_return(fake_group)
        is_expected.to eq 'mygroup'
      end
    end # /context with an integer

    context 'with a string' do
      let(:user) { 'myuser' }
      it do
        expect(Etc).to receive(:getpwnam).with('myuser').and_return(fake_user)
        expect(Etc).to receive(:getgrgid).with(123).and_return(fake_group)
        is_expected.to eq 'mygroup'
      end
    end # /context with a string

    context 'with an invalid user' do
      let(:user) { 'myuser' }
      it do
        expect(Etc).to receive(:getpwnam).with('myuser').and_raise(ArgumentError)
        is_expected.to eq 'myuser'
      end
    end # /context with an invalid user

    context 'with an invalid group' do
      let(:user) { 'myuser' }
      it do
        expect(Etc).to receive(:getpwnam).with('myuser').and_return(fake_user)
        expect(Etc).to receive(:getgrgid).with(123).and_raise(ArgumentError)
        is_expected.to eq 'myuser'
      end
    end # /context with an invalid group
  end # /describe .primary_group_for
end
