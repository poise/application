#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Library:: default
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

require "chef/mixin/from_file"

class Chef
  class Resource
    # Globally update the blocklists to prevent infinite recursion in #to_json and similar
    FORBIDDEN_IVARS.concat [:@application, :@application_provider]
    HIDDEN_IVARS.concat [:@application, :@application_provider]

    class Application
      module OptionsCollector
        def options
          @options ||= {}
        end

        def method_missing(method_sym, value=nil, &block)
          super
        rescue NameError
          value ||= block
          method_sym = method_sym.to_s.chomp('=').to_sym
          options[method_sym] = value if value
          options[method_sym] ||= nil
        end
      end
    end

    module ApplicationBase
      def self.included(klass)
        klass.actions :before_compile, :before_deploy, :before_migrate, :before_symlink, :before_restart, :after_restart
        klass.attribute :id, :kind_of => String, :name_attribute => true
        klass.attribute :environment, :kind_of => Hash, :default => {}
        klass.attribute :purge_before_symlink, :kind_of => Array, :default => []
        klass.attribute :create_dirs_before_symlink, :kind_of => Array, :default => []
        klass.attribute :symlinks, :kind_of => Hash, :default => {}
        klass.attribute :symlink_before_migrate, :kind_of => Hash, :default => {}
        klass.attribute :migration_command, :kind_of => [String, NilClass], :default => nil
        klass.attribute :application
        klass.attribute :application_provider
        klass.attribute :type
      end

      def restart_command(arg=nil, &block)
        arg ||= block
        raise "Invalid restart command" unless !arg || arg.is_a?(String) || arg.is_a?(Proc)
        @restart_command = arg if arg
        @restart_command
      end

      def method_missing(name, *args)
        if application.respond_to? name
          application.send(name, *args)
        else
          super
        end
      end

      class OptionsBlock
        include Chef::Resource::Application::OptionsCollector
      end

      def options_block(options=nil, &block)
        options ||= {}
        if block
          collector = OptionsBlock.new
          collector.instance_eval(&block)
          options.update(collector.options)
        end
        options
      end

      def find_matching_role(role, single=true, &block)
        return nil if !role
        nodes = []
        if node['roles'].include? role
          nodes << node
        end
        if !single || nodes.empty?
          search(:node, "role:#{role} AND chef_environment:#{node.chef_environment}") do |n|
            nodes << n
          end
        end
        if block
          nodes.each do |n|
            yield n
          end
        else
          if single
            nodes.first
          else
            nodes
          end
        end
      end

      def find_database_server(role)
        dbm = find_matching_role(role)
        Chef::Log.warn("No node with role #{role}") if role && !dbm

        if respond_to?(:database) && database.has_key?('host')
          database['host']
        elsif dbm && dbm.attribute?('cloud')
          dbm['cloud']['local_ipv4']
        elsif dbm
          dbm['ipaddress']
        end
      end
    end
  end

  class Provider
    module ApplicationBase

      def self.included(klass)
        klass.send(:include, Chef::Mixin::FromFile)
      end

      def deploy_provider
        @deploy_provider ||= begin
          version = Chef::Version.new(Chef::VERSION)
          deploy_provider = if version.major > 10 || version.minor >= 14
            Chef::Platform.provider_for_resource(@deploy_resource, :nothing)
          else
            Chef::Platform.provider_for_resource(@deploy_resource)
          end
          deploy_provider.load_current_resource
          deploy_provider
        end
      end

      def release_path
        deploy_provider.release_path
      end

      def shared_path
        @deploy_resource.shared_path
      end

      def callback(what, callback_code=nil)
        Chef::Log.debug("Got callback #{what}: #{callback_code.inspect}")
        @collection = Chef::ResourceCollection.new
        case callback_code
        when Proc
          Chef::Log.info "#{@new_resource} running callback #{what}"
          safe_recipe_eval(&callback_code)
        when String
          callback_file = "#{release_path}/#{callback_code}"
          unless ::File.exist?(callback_file)
            raise RuntimeError, "Can't find your callback file #{callback_file}"
          end
          run_callback_from_file(callback_file)
        when nil
          nil
        else
          raise RuntimeError, "You gave me a callback I don't know what to do with: #{callback_code.inspect}"
        end
      end

      def run_callback_from_file(callback_file)
        if ::File.exist?(callback_file)
          Dir.chdir(release_path) do
            Chef::Log.info "#{@new_resource} running deploy hook #{callback_file}"
            safe_recipe_eval { from_file(callback_file) }
          end
        end
      end

      def safe_recipe_eval(&callback_code)
        recipe_eval(&callback_code)
        converge if respond_to?(:converge)
      end
    end
  end
end
