#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Provider:: rails
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

action :before_compile do

  new_resource.migration_command "rake db:migrate" if !new_resource.migration_command

  new_resource.environment.update({
    "RAILS_ENV" => new_resource.environment_name,
  })

  new_resource.symlink_before_migrate.update({
    "database.yml" => "config/database.yml",
    "memcached.yml" => "config/memcached.yml",
  })

end

action :before_deploy do

  new_resource.environment['RAILS_ENV'] = new_resource.environment_name

  new_resource.gems.each do |gem, ver|
    gem_package gem do
      action :install
      version ver if ver && ver.length > 0
    end
  end

  if new_resource.database_master_role
    dbm = nil
    # If we are the database master
    if node['roles'].include?(new_resource.database_master_role)
      dbm = node
    else
    # Find the database master
      results = search(:node, "role:#{new_resource.database_master_role} AND chef_environment:#{node.chef_environment}", nil, 0, 1)
      rows = results[0]
      if rows.length == 1
        dbm = rows[0]
      end
    end

    # Assuming we have one...
    if dbm
      template "#{new_resource.path}/shared/database.yml" do
        source "database.yml.erb"
        cookbook "application"
        owner new_resource.owner
        group new_resource.group
        mode "644"
        variables(
          :host => (dbm.attribute?('cloud') ? dbm['cloud']['local_ipv4'] : dbm['ipaddress']),
          :database => new_resource.database,
          :rails_env => new_resource.environment_name
        )
      end
    else
      Chef::Log.warn("No node with role #{new_resource.database_master_role}, database.yml not rendered!")
    end
  end

  if new_resource.memcached_role
    results = search(:node, "role:#{new_resource.memcached_role} AND chef_environment:#{node.chef_environment} NOT hostname:#{node[:hostname]}")
    if results.length == 0
      if node['roles'].include?(new_resource.memcached_role)
        results << node
      end
    end
    template "#{new_resource.path}/shared/memcached.yml" do
      source "memcached.yml.erb"
      cookbook "application"
      owner new_resource.owner
      group new_resource.group
      mode "644"
      variables(
        :memcached_envs => new_resource.memcached,
        :hosts => results.sort_by { |r| r.name }
      )
    end
  end

end

action :before_migrate do

  gem_names = new_resource.gems.map{|gem, ver| gem}
  if gem_names.include?('bundler')
    Chef::Log.info "Running bundle install"
    link "#{new_resource.release_path}/vendor/bundle" do
      to "#{new_resource.path}/shared/vendor_bundle"
    end
    common_groups = %w{development test cucumber staging production}
    bundler_deployment = new_resource.bundler_deployment
    if bundler_deployment.nil?
      # Check for a Gemfile.lock
      bundler_deployment = ::File.exists?(::File.join(new_resource.release_path, "Gemfile.lock"))
    end
    execute "bundle install #{bundler_deployment ? "--deployment " : ""}--without #{(common_groups -([node.chef_environment])).join(' ')}" do
      ignore_failure true
      cwd new_resource.release_path
    end
  elsif gem_names.include?('bundler08')
    Chef::Log.info "Running gem bundle"
    execute "gem bundle" do
      ignore_failure true
      cwd new_resource.release_path
    end
  else
    # chef runs before_migrate, then symlink_before_migrate symlinks, then migrations,
    # yet our before_migrate needs database.yml to exist (and must complete before
    # migrations).
    #
    # maybe worth doing run_symlinks_before_migrate before before_migrate callbacks,
    # or an add'l callback.
    execute "(ln -s ../../../shared/database.yml config/database.yml && rake gems:install); rm config/database.yml" do
      ignore_failure true
      cwd new_resource.release_path
    end
  end

  if new_resource.migration_command.include?('rake') && !gem_names.include?('rake')
    gem_package "rake" do
      action :install
    end
  end

end

action :before_symlink do

  ruby_block "remove_run_migrations" do
    block do
      if node.role?("#{new_resource.id}_run_migrations")
        Chef::Log.info("Migrations were run, removing role[#{new_resource.id}_run_migrations]")
        node.run_list.remove("role[#{new_resource.id}_run_migrations]")
      end
    end
  end

end

action :before_restart do
end

action :after_restart do
end

