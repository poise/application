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

require 'chef/dsl/recipe' # On 12.4+ this will pull in chef/dsl/resources.
require 'chef/resource'
require 'chef/provider'
require 'poise'


module PoiseApplication
  module Resources
    module Application
      class Resource < Chef::Resource
        include Poise(container: true, container_namespace: false)
        provides(:application)
        actions(:deploy)

        attribute(:path, kind_of: String, name_attribute: true)
        attribute(:environment, kind_of: Hash, default: lazy { Mash.new })
        attribute(:owner, kind_of: String)
        attribute(:group, kind_of: String)

        def initialize(*args)
          super
          _rewire_dsl!
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
                []
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
            # Find the part to trim. Check for LWRP first, then just application_.
            trim = application_cookbooks.find {|cookbook_name| name.start_with?(cookbook_name) && name != cookbook_name } || 'application'
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

      class Provider < Chef::Provider
        include Poise
        provides(:application)

        def action_deploy
          notifying_block do
            directory new_resource.path do
              owner new_resource.owner
              group new_resource.group
              mode '755'
            end
          end
        end
      end
    end
  end
end
