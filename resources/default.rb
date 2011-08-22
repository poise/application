#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Resource:: default
#
# Copyright:: 2011, Opscode, Inc <legal@opscode.com>
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

require 'weakref'

include Chef::Mixin::RecipeDefinitionDSLCore

def initialize(*args)
  super
  @action = :deploy
  @sub_resources = []
end

actions :deploy, :remove

attribute :id, :kind_of => String, :name_attribute => true
attribute :environment_name, :kind_of => String, :default => (node.chef_environment =~ /_default/ ? "production" : node.chef_environment)
attribute :path, :kind_of => String
attribute :owner, :kind_of => String
attribute :group, :kind_of => String
attribute :revision, :kind_of => String
attribute :repository, :kind_of => String
attribute :environment, :kind_of => Hash, :default => {}
attribute :deploy_key, :kind_of => [String, NilClass], :default => nil
attribute :force, :kind_of => [TrueClass, FalseClass], :default => false
attribute :purge_before_symlink, :kind_of => Array, :default => []
attribute :create_dirs_before_symlink, :kind_of => Array, :default => []
attribute :symlinks, :kind_of => Hash, :default => {}
attribute :symlink_before_migrate, :kind_of => Hash, :default => {}
attribute :migrate, :kind_of => [TrueClass, FalseClass], :default => false
attribute :migration_command, :kind_of => [String, NilClass], :default => nil
attribute :restart_command, :kind_of => [String, NilClass], :default => nil
attribute :packages, :kind_of => [Array, Hash], :default => []
attr_reader :sub_resources

# Callback fires before deploy is started.
def before_deploy(arg=nil, &block)
  arg ||= block
  set_or_return(:before_deploy, arg, :kind_of => [Proc, String])
end

# Callback fires before migration is run.
def before_migrate(arg=nil, &block)
  arg ||= block
  set_or_return(:before_migrate, arg, :kind_of => [Proc, String])
end

# Callback fires before symlinking
def before_symlink(arg=nil, &block)
  arg ||= block
  set_or_return(:before_symlink, arg, :kind_of => [Proc, String])
end

# Callback fires before restart
def before_restart(arg=nil, &block)
  arg ||= block
  set_or_return(:before_restart, arg, :kind_of => [Proc, String])
end

# Callback fires after restart
def after_restart(arg=nil, &block)
  arg ||= block
  set_or_return(:after_restart, arg, :kind_of => [Proc, String])
end

def method_missing(name, &block)
  begin
    resource = super("application_#{name.to_s}", id, &block)
  rescue NoMethodError
    resource = super(name, id, &block)
  end
  # Enforce action :nothing in case people forget
  resource.action :nothing
  # Make this a weakref to prevent a cycle between the application resource and the sub resources
  resource.application WeakRef.new(self)
  @sub_resources << resource
  resource
end
