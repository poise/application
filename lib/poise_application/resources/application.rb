#
# Copyright 2015-2016, Noah Kantrowitz
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

require 'chef/dsl/recipe' # On 12.4+ this will pull in chef/dsl/resources.
require 'chef/resource'
require 'chef/provider'
require 'poise'


module PoiseApplication
  module Resources
    # (see Application::Resource)
    # @since 5.0.0
    module Application
      # An `application` resource to manage application deployment.
      #
      # @since 5.0.0
      # @provides application
      # @action deploy
      # @action start
      # @action stop
      # @action restart
      # @action reload
      # @example
      #   application '/srv/myapp' do
      #     git '...'
      #     poise_service 'myapp' do
      #       command '/srv/myapp/main'
      #     end
      #   end
      class Resource < Chef::Resource
        include Poise(container: true, container_namespace: false)
        provides(:application)
        actions(:deploy, :start, :stop, :restart, :reload)

        # @!attribute path
        #   Application base path.
        #   @return [String]
        attribute(:path, kind_of: String, name_attribute: true)
        # @!attribute environment
        #   Environment variables to set for the whole application.
        #   @return [Hash<String, String>]
        attribute(:environment, kind_of: Hash, default: lazy { Mash.new })
        # @!attribute owner
        #   System user that will own the application. This can be overriden in
        #   individual subresources.
        #   @return [String]
        attribute(:owner, kind_of: String)
        # @!attribute group
        #   System group that will own the application. This can be overriden in
        #   individual subresources.
        #   @return [String]
        attribute(:group, kind_of: String)
        # @!attribute action_on_update
        #   Action to run when any subresource is updated. Defaults to `:restart`.
        #   @return [String, Symbol, nil, false]
        attribute(:action_on_update, kind_of: [Symbol, String, NilClass, FalseClass], default: :restart)
        # @!attribute action_on_update_immediately
        #   Run the {#action_on_update} notification with `:immediately`.
        #   @return [Boolean]
        attribute(:action_on_update_immediately, equal_to: [true, false], default: false)

        # Run the DSL rewire when the resource object is created.
        # @api private
        def initialize(*args)
          super
          _rewire_dsl! if node
        end

        # Application-specific state values used as a way to communicate between
        # subresources.
        #
        # @return [Mash]
        # @example
        #   if new_resource.parent && new_resource.parent.app_state['gemfile_path']
        def app_state
          @app_state ||= Mash.new(environment: environment)
        end

        # Override Container#register_subresource to add our action_on_update.
        #
        # @api private
        def register_subresource(resource)
          super.tap do |added|
            if added && action_on_update
              Chef::Log.debug("[#{self}] Registering #{action_on_update_immediately ? 'immediate ' : ''}#{action_on_update} notification from #{resource}")
              resource.notifies action_on_update.to_sym, self, (action_on_update_immediately ? :immediately : :delayed)
            end
          end
        end

        private

        # Find all resources that need to be rewired. This is anything with a
        # name starting with application_.
        #
        # @return [Array<String>]
        def _rewire_resources
          if defined?(Chef::DSL::Resources)
            # Chef >= 12.4.
            Chef::DSL::Resources.instance_methods
          else
            # Chef < 12.4 >= 12.0.
            Chef::Resource.descendants.map do |klass|
              klass.node_map.instance_variable_get(:@map).keys + if klass.dsl_name.include?('::')
                # Probably not valid.
                # :nocov:
                []
                # :nocov:
              else
                # Needed for things that don't call provides().
                [klass.dsl_name]
              end
            end.flatten
          end.map {|name| name.to_s }.select {|name| name.start_with?('application_') }.uniq
        end

        # Find all cookbooks that might contain LWRPs matching our name scheme.
        #
        # @return [Array<String>]
        def _rewire_cookbooks
          # Run context might be unset during test setup.
          if run_context
            run_context.cookbook_collection.keys.select {|cookbook_name| cookbook_name.start_with?('application_') }
          else
            []
          end
        end

        # Build the mapping of new_name => old_name for each resource to rewire.
        #
        # @return [Hash<String, String>]
        def _rewire_map
          application_cookbooks = _rewire_cookbooks
          _rewire_resources.inject({}) do |memo, name|
            # Grab the resource class to check if it is an LWRP.
            klass = Chef::Resource.resource_for_node(name.to_sym, node)
            # Find the part to trim. Check for LWRP first, then just application_.
            trim = if klass < Chef::Resource::LWRPBase
              application_cookbooks.find {|cookbook_name| name.start_with?(cookbook_name) && name != cookbook_name } || 'application'
            else
              # Non-LWRPs are assumed to have a better name.
              'application'
            end
            # Map trimmed to untrimmed.
            memo[name[trim.length+1..-1]] = name
            memo
          end
        end

        # Build new DSL methods to implement the foo -> application_foo behavior.
        #
        # @return [void]
        def _rewire_dsl!
          # Generate stub methods for all the rewiring.
          _rewire_map.each do |new_name, old_name|
            # This is defined as a singleton method on self so it looks like
            # the DSL but is scoped to just this context.
            define_singleton_method(new_name) do |name=nil, *args, &block|
              # Store the caller to correct the source_line.
              created_at = caller[0]
              public_send(old_name, name, *args) do
                # Set the declared type to be the native name.
                self.declared_type = self.class.resource_name
                # Fix the source location. For Chef 12.4 we could do this with the
                # declared_at parameter on the initial send.
                self.source_line = created_at
                # Run the original block.
                instance_exec(&block) if block
              end
            end
          end
        end
      end

      # Provider for `application`.
      #
      # @since 5.0.0
      # @see Resource
      # @provides application
      class Provider < Chef::Provider
        include Poise
        provides(:application)

        # `deploy` action for `application`. Creates the application base folder.
        #
        # @return [void]
        def action_deploy
          notifying_block do
            directory new_resource.path do
              owner new_resource.owner
              group new_resource.group
              mode '755'
            end
          end
        end

        # `start` action for `application`. Proxies to subresources.
        #
        # @return [void]
        def action_start
          proxy_action(:start)
        end

        # `stop` action for `application`. Proxies to subresources.
        #
        # @return [void]
        def action_stop
          proxy_action(:stop)
        end

        # `restart` action for `application`. Proxies to subresources.
        #
        # @return [void]
        def action_restart
          proxy_action(:restart)
        end

        # `reload` action for `application`. Proxies to subresources.
        #
        # @return [void]
        def action_reload
          proxy_action(:reload)
        end

        private

        # Proxy an action to any subresources that support it.
        #
        # @param action [Symbol] Action to proxy.
        # @return [void]
        def proxy_action(action)
          Chef::Log.debug("[#{new_resource} Running proxied #{action} action")
          new_resource.subresources.each do |r|
            begin
              r.run_action(action) if r.allowed_actions.include?(action)
            rescue Chef::Exceptions::UnsupportedAction
              # Don't care, just move on.
            end
          end
        end

      end
    end
  end
end
