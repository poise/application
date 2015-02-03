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

describe Chef::Resource::PoiseGit, :focus do
  step_into(:poise_git)
  recipe do
    poise_git '/test' do
      user 'root'
      repository 'https://example.com/test.git'
      revision 'd44ec06d0b2a87732e91c005ed2048c824fd63ed'
      deploy_key 'secretkey'
    end
  end

  before do
    # Don't actually run the real thing
    expect_any_instance_of(Chef::Provider::PoiseGit).to receive(:action_sync).and_return(nil)
    # Unwrap notifying_block
    allow_any_instance_of(Chef::Provider::PoiseGit).to receive(:notifying_block) {|&block| block.call }
  end

  it { is_expected.to sync_poise_git('/test').with(repository: 'https://example.com/test.git', revision: 'd44ec06d0b2a87732e91c005ed2048c824fd63ed', deploy_key: 'secretkey', ssh_wrapper: File.expand_path('~root/ssh_wrapper_2089348824')) }
  it { is_expected.to render_file(File.expand_path('~root/id_deploy_2089348824')).with_content('secretkey') }
  it { is_expected.to render_file(File.expand_path('~root/ssh_wrapper_2089348824')).with_content(%Q{#!/bin/sh\n/usr/bin/env ssh -o "StrictHostKeyChecking=no" -i "#{File.expand_path('~root/id_deploy_2089348824')}" $@\n}) }

  context 'with a local path to a deploy key' do
    recipe do
      poise_git '/test' do
        user 'root'
        repository 'https://example.com/test.git'
        revision 'd44ec06d0b2a87732e91c005ed2048c824fd63ed'
        deploy_key '/etc/key'
      end
    end

    it { is_expected.to sync_poise_git('/test').with(repository: 'https://example.com/test.git', revision: 'd44ec06d0b2a87732e91c005ed2048c824fd63ed', deploy_key: '/etc/key', ssh_wrapper: File.expand_path('~root/ssh_wrapper_2089348824')) }
    it { is_expected.to render_file(File.expand_path('~root/ssh_wrapper_2089348824')).with_content(%Q{#!/bin/sh\n/usr/bin/env ssh -o "StrictHostKeyChecking=no" -i "/etc/key" $@\n}) }
  end

  context 'with strict SSH' do
    recipe do
      poise_git '/test' do
        user 'root'
        repository 'https://example.com/test.git'
        revision 'd44ec06d0b2a87732e91c005ed2048c824fd63ed'
        deploy_key 'secretkey'
        strict_ssh true
      end
    end

    it { is_expected.to sync_poise_git('/test').with(repository: 'https://example.com/test.git', revision: 'd44ec06d0b2a87732e91c005ed2048c824fd63ed', deploy_key: 'secretkey', ssh_wrapper: File.expand_path('~root/ssh_wrapper_2089348824')) }
    it { is_expected.to render_file(File.expand_path('~root/ssh_wrapper_2089348824')).with_content(%Q{#!/bin/sh\n/usr/bin/env ssh -i "#{File.expand_path('~root/id_deploy_2089348824')}" $@\n}) }
  end
end
