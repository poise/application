#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Provider:: default
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

include Chef::Provider::ApplicationBase

action :deploy do
  # Alias to a variable so I can use in sub-resources
  new_resource = @new_resource

  new_resource.sub_resources.each do |resource|
    resource.application_provider self
    resource.run_action :before_compile
  end

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
    ruby_block "write_key" do
      block do
        f = ::File.open("#{new_resource.path}/id_deploy", "w")
        f.print(new_resource.deploy_key)
        f.close
      end
      not_if do ::File.exists?("#{new_resource.path}/id_deploy"); end
    end

    file "#{new_resource.path}/id_deploy" do
      owner new_resource.owner
      group new_resource.group
      mode '0600'
    end

    template "#{new_resource.path}/deploy-ssh-wrapper" do
      source "deploy-ssh-wrapper.erb"
      owner new_resource.owner
      group new_resource.group
      mode "0755"
      variables :id => new_resource.id, :deploy_to => new_resource.path
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

  @deploy_resource = send(new_resource.strategy.to_sym, new_resource.name) do
    revision new_resource.revision
    repository new_resource.repository
    user new_resource.owner
    group new_resource.group
    deploy_to new_resource.path
    ssh_wrapper "#{new_resource.path}/deploy-ssh-wrapper" if new_resource.deploy_key
    shallow_clone true
    all_environments = ([new_resource.environment]+new_resource.sub_resources.map{|res| res.environment}).inject({}){|acc, val| acc.merge(val)}
    environment all_environments
    migrate new_resource.migrate
    all_migration_commands = ([new_resource.migration_command]+new_resource.sub_resources.map{|res| res.migration_command}).select{|cmd| cmd && !cmd.empty?}
    migration_command all_migration_commands.join(' && ')
    restart_command do
      ([new_resource]+new_resource.sub_resources).each do |res|
        cmd = res.restart_command
        if cmd.is_a? Proc
          provider = Chef::Platform.provider_for_resource(res)
          provider.load_current_resource
          provider.instance_eval(&cmd)
        elsif cmd && !cmd.empty?
          execute cmd do
            user new_resource.owner
            group new_resource.group
            environment all_environments
          end
        end
      end
    end
    purge_before_symlink new_resource.purge_before_symlink
    create_dirs_before_symlink new_resource.create_dirs_before_symlink
    symlinks new_resource.symlinks
    all_symlinks_before_migrate = [new_resource.symlink_before_migrate]+new_resource.sub_resources.map{|res| res.symlink_before_migrate}
    symlink_before_migrate all_symlinks_before_migrate.inject({}){|acc, val| acc.merge(val)}
    # Yes, this needs to be refactored together
    before_migrate do
      new_resource.sub_resources.each do |resource|
        saved_run_context = resource.instance_variable_get :@run_context
        resource.instance_variable_set :@run_context, @run_context
        resource.run_action :before_migrate
        resource.instance_variable_set :@run_context, saved_run_context
      end
      callback(:before_migrate, new_resource.before_migrate)
    end
    before_symlink do
      new_resource.sub_resources.each do |resource|
        saved_run_context = resource.instance_variable_get :@run_context
        resource.instance_variable_set :@run_context, @run_context
        resource.run_action :before_symlink
        resource.instance_variable_set :@run_context, saved_run_context
      end
      callback(:before_symlink, new_resource.before_symlink)
    end
    before_restart do
      new_resource.sub_resources.each do |resource|
        saved_run_context = resource.instance_variable_get :@run_context
        resource.instance_variable_set :@run_context, @run_context
        resource.run_action :before_restart
        resource.instance_variable_set :@run_context, saved_run_context
      end
      callback(:before_restart, new_resource.before_restart)
    end
    after_restart do
      new_resource.sub_resources.each do |resource|
        saved_run_context = resource.instance_variable_get :@run_context
        resource.instance_variable_set :@run_context, @run_context
        resource.run_action :after_restart
        resource.instance_variable_set :@run_context, saved_run_context
      end
      callback(:after_restart, new_resource.after_restart)
    end
  end

end