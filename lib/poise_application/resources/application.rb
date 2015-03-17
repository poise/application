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

require 'chef/resource'
require 'chef/provider'
require 'poise'


class Chef
  class Resource::Application < Resource
    include Poise(container: true, container_namespace: false)
    default_action(:deploy)

    attribute(:path, kind_of: String, name_attribute: true)
    attribute(:environment, kind_of: String, default: lazy { node.chef_environment == '_default' ? 'production' : node.chef_environment })
    attribute(:owner, kind_of: String)
    attribute(:group, kind_of: String)

    # Application-specific state values used as a way to communicate between
    # subresources.
    #
    # @api public
    # @return [Mash]
    # @example
    #   if new_resource.parent && new_resource.parent.app_state['gemfile_path']
    def app_state
      @app_state ||= Mash.new
    end

    def method_missing(method_symbol, *args, &block)
      lookup_path = [:"application_#{method_symbol}"]
      run_context.cookbook_collection.each do |cookbook_name, cookbook_ver|
        if cookbook_name.start_with?('application_')
          lookup_path << :"#{cookbook_name}_#{method_symbol}"
        end
      end
      lookup_path << method_symbol
      # Find the first that exists, or just use the method_name for the error message
      candidate_resource = lookup_path.find {|name| have_resource_class_for?(name) } || method_symbol
      # Give a default name of ''
      args << '' if args.empty?
      # Store the caller to correct the source_line.
      created_at = caller[0]
      super(candidate_resource, *args) do
        # Fix the source location.
        self.source_line = created_at
        # Run the original block.
        instance_exec(&block) if block
      end
    end
  end

  class Provider::Application < Provider
    include Poise

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
