#
# Author:: Noah Kantrowitz <noah@opscode.com>
# Cookbook Name:: application
# Library:: default
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

class Chef
  class Resource
    # Globally update the blocklists to prevent infinite recursion in #to_json and similar
    FORBIDDEN_IVARS += [:@application, :@application_provider]
    HIDDEN_IVARS += [:@application, :@application_provider]

    module ApplicationBase
      def self.included(klass)
        klass.actions :before_compile, :before_deploy, :before_migrate, :before_symlink, :before_restart, :after_restart
        klass.attribute :id, :kind_of => String, :name_attribute => true
        klass.attribute :environment, :kind_of => Hash, :default => {}
        klass.attribute :purge_before_symlink, :kind_of => Array, :default => []
        klass.attribute :create_dirs_before_symlink, :kind_of => Array, :default => []
        klass.attribute :symlinks, :kind_of => Hash, :default => {}
        klass.attribute :symlink_before_migrate, :kind_of => Hash, :default => {}
        klass.attribute :migration_command, :kind_of => [String, NilClass], :default => 'rake db:migrate'
        klass.attribute :restart_command, :kind_of => [String, NilClass], :default => nil
        klass.attribute :application
        klass.attribute :application_provider
      end

      def method_missing(name, *args)
        if application.respond_to? name
          application.send(name, *args)
        else
          super
        end
      end

      def release_path
        application_provider.release_path
      end
    end
  end

  class Provider
    module ApplicationBase

      def self.included(klass)
        klass.extend Chef::Mixin::FromFile
      end

      def release_path
        if !@deploy_provider
          #@deploy_provider = Chef::Platform.provider_for_resource(@run_context.resource_collection.find(:deploy_revision => @new_resource.id))
          @deploy_provider = Chef::Platform.provider_for_resource(@deploy_resource)
          @deploy_provider.load_current_resource
        end
        @deploy_provider.release_path
      end

      def callback(what, callback_code=nil)
        Chef::Log.debug("Got callback #{what}: #{callback_code.inspect}")
        @collection = Chef::ResourceCollection.new
        case callback_code
        when Proc
          Chef::Log.info "#{@new_resource} running callback #{what}"
          recipe_eval(&callback_code)
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
            recipe_eval { from_file(callback_file) }
          end
        end
      end

    end
  end
end
