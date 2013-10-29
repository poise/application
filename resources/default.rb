#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Resource:: default
#
# Copyright:: 2011-2012, Opscode, Inc <legal@opscode.com>
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

include Chef::DSL::Recipe

def initialize(*args)
  super
  @action = :deploy
  @sub_resources = []
end

actions :deploy, :force_deploy

attribute :name, :kind_of => String, :name_attribute => true
attribute :environment_name, :kind_of => String, :default => (node.chef_environment =~ /_default/ ? "production" : node.chef_environment)
attribute :path, :kind_of => String
attribute :owner, :kind_of => String
attribute :group, :kind_of => String
attribute :strategy, :kind_of => [String, Symbol], :default => :deploy_revision
attribute :scm_provider, :kind_of => [Class, String, Symbol]
attribute :revision, :kind_of => String
attribute :repository, :kind_of => String
attribute :enable_submodules, :kind_of => [TrueClass, FalseClass], :default => false
attribute :environment, :kind_of => Hash, :default => {}
attribute :deploy_key, :kind_of => [String, NilClass], :default => nil
attribute :shallow_clone, :kind_of => [TrueClass, FalseClass], :default => true
attribute :force, :kind_of => [TrueClass, FalseClass], :default => false
attribute :rollback_on_error, :kind_of => [TrueClass, FalseClass], :default => true
attribute :purge_before_symlink, :kind_of => Array, :default => []
attribute :create_dirs_before_symlink, :kind_of => Array, :default => []
attribute :symlinks, :kind_of => Hash, :default => {}
attribute :symlink_before_migrate, :kind_of => Hash, :default => {}
attribute :migrate, :kind_of => [TrueClass, FalseClass], :default => false
attribute :migration_command, :kind_of => [String, NilClass], :default => nil
attribute :packages, :kind_of => [Array, Hash], :default => []
attribute :application_provider
attr_reader :sub_resources

def restart_command(arg=nil, &block)
  arg ||= block
  set_or_return(:restart_command, arg, :kind_of => [Proc, String])
end

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

def release_path
  application_provider.release_path
end

def shared_path
  application_provider.shared_path
end

def method_missing(name, *args, &block)
  # Build the set of names to check for a valid resource
  lookup_path = ["application_#{name}"]
  run_context.cookbook_collection.each do |cookbook_name, cookbook_ver|
    if cookbook_name.start_with?("application_")
      lookup_path << "#{cookbook_name}_#{name}"
    end
  end
  lookup_path << name
  resource = nil
  # Try to find our resource
  lookup_path.each do |resource_name|
    begin
      Chef::Log.debug "Trying to load application resource #{resource_name} for #{name}"
      resource = super(resource_name.to_sym, self.name, &block)
      break
    rescue NameError => e
      # Works on any MRI ruby
      if e.name == resource_name.to_sym || e.inspect =~ /\b#{resource_name}\b/
        next
      else
        raise e
      end
    end
  end
  raise NameError, "No resource found for #{name}. Tried #{lookup_path.join(', ')}" unless resource
  # Enforce action :nothing in case people forget
  resource.action :nothing
  # Make this a weakref to prevent a cycle between the application resource and the sub resources
  resource.application WeakRef.new(self)
  resource.type name
  @sub_resources << resource
  resource
end

def do_i_respond_to?(*args)
  name = args.first.to_s
  # Build the set of names to check for a valid resource
  lookup_path = ["application_#{name}"]
  run_context.cookbook_collection.each do |cookbook_name, cookbook_ver|
    if cookbook_name.start_with?("application_")
      lookup_path << "#{cookbook_name}_#{name}"
    end
  end
  lookup_path << name
  found = false
  # Try to find our resource
  lookup_path.each do |resource_name|
    begin
      Chef::Log.debug "Looking for application resource #{resource_name} for #{name}"
      Chef::Resource.resource_for_node(resource_name.to_sym, node)
      found = true
      break
    rescue NameError => e
      # Keep calm and carry on
    end
  end
  found
end

# If we are using a current version of ruby, use respond_to_missing?
# instead of respond_to? so we provide proper behavior
if(Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('1.9.1'))
  def respond_to_missing?(*args)
    super || do_i_respond_to?(*args)
  end
else
  def respond_to?(*args)
    super || do_i_respond_to?(*args)
  end
end

def to_ary
  nil
end
alias :to_a :to_ary
