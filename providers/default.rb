#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Provider:: default
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

include ApplicationCookbook::ProviderBase

action :deploy do

  before_compile

  before_deploy

  run_deploy

end

action :force_deploy do

  before_compile

  before_deploy

  run_deploy(true)

end

action :restart do

  before_compile

  run_actions_with_context(:before_restart, @run_context)

  run_restart

  run_actions_with_context(:after_restart, @run_context)

  @new_resource.updated_by_last_action(true)

end

protected

def before_compile
  new_resource.application_provider self
  new_resource.sub_resources.each do |resource|
    resource.application_provider self
    resource.run_action :before_compile
  end
end

def before_deploy
  new_resource.packages.each do |pkg,ver|
    package pkg do
      action :install
      version ver if ver && ver.length > 0
    end
  end

  directory new_resource.path do
    owner new_resource.owner
    group new_resource.group
    mode '0755'
    recursive true
  end

  directory "#{new_resource.path}/shared" do
    owner new_resource.owner
    group new_resource.group
    mode '0755'
    recursive true
  end

  if new_resource.deploy_key
    file "#{new_resource.path}/id_deploy" do
      content new_resource.deploy_key
      owner new_resource.owner
      group new_resource.group
      mode '0600'
    end

    template "#{new_resource.path}/deploy-ssh-wrapper" do
      source "deploy-ssh-wrapper.erb"
      cookbook "application"
      owner new_resource.owner
      group new_resource.group
      mode "0755"
      variables :id => new_resource.name, :deploy_to => new_resource.path
    end
  end

  ruby_block "#{new_resource.name} before_deploy" do
    block do
      new_resource.sub_resources.each do |resource|
        resource.run_action :before_deploy
      end
      callback(:before_deploy, new_resource.before_deploy)
    end
  end
end

def run_deploy(force = false)
  # Alias to a variable so I can use in sub-resources
  new_resource = @new_resource
  # Also alias to variable so it can be used in sub-resources
  app_provider = self

  @deploy_resource = send(new_resource.strategy.to_sym, new_resource.name) do
    action force ? :force_deploy : :deploy
    scm_provider new_resource.scm_provider
    revision new_resource.revision
    repository new_resource.repository
    enable_submodules new_resource.enable_submodules
    user new_resource.owner
    group new_resource.group
    deploy_to new_resource.path
    ssh_wrapper "#{new_resource.path}/deploy-ssh-wrapper" if new_resource.deploy_key
    shallow_clone new_resource.shallow_clone
    rollback_on_error new_resource.rollback_on_error
    all_environments = ([new_resource.environment]+new_resource.sub_resources.map{|res| res.environment}).inject({}){|acc, val| acc.merge(val)}
    environment all_environments
    migrate new_resource.migrate
    all_migration_commands = ([new_resource.migration_command]+new_resource.sub_resources.map{|res| res.migration_command}).select{|cmd| cmd && !cmd.empty?}
    migration_command all_migration_commands.join(' && ')
    restart_command do
      ([new_resource]+new_resource.sub_resources).each do |res|
        cmd = res.restart_command
        if cmd.is_a? Proc
          app_provider.deploy_provider.instance_eval(&cmd) # @see libraries/default.rb
        elsif cmd && !cmd.empty?
          execute cmd do
            user new_resource.owner
            group new_resource.group
            environment all_environments
          end
        end
      end
    end
    purge_before_symlink (new_resource.purge_before_symlink + new_resource.sub_resources.map(&:purge_before_symlink)).flatten
    create_dirs_before_symlink (new_resource.create_dirs_before_symlink + new_resource.sub_resources.map(&:create_dirs_before_symlink)).flatten
    all_symlinks = [new_resource.symlinks]+new_resource.sub_resources.map{|res| res.symlinks}
    symlinks all_symlinks.inject({}){|acc, val| acc.merge(val)}
    all_symlinks_before_migrate = [new_resource.symlink_before_migrate]+new_resource.sub_resources.map{|res| res.symlink_before_migrate}
    symlink_before_migrate all_symlinks_before_migrate.inject({}){|acc, val| acc.merge(val)}
    before_migrate do
      app_provider.send(:run_actions_with_context, :before_migrate, @run_context)
    end
    before_symlink do
      app_provider.send(:run_actions_with_context, :before_symlink, @run_context)
    end
    before_restart do
      app_provider.send(:run_actions_with_context, :before_restart, @run_context)
    end
    after_restart do
      app_provider.send(:run_actions_with_context, :after_restart, @run_context)
    end
  end
end

def run_actions_with_context(action, context)
  new_resource.sub_resources.each do |resource|
    saved_run_context = resource.instance_variable_get :@run_context
    resource.instance_variable_set :@run_context, context
    resource.run_action action
    resource.instance_variable_set :@run_context, saved_run_context
  end
  callback(action, new_resource.send(action))
end
