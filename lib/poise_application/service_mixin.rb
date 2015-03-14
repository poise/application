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
require 'poise_service/resource'

require 'poise_application/utils'


module PoiseApplication
  # Mixin for application services. This is any resource that will be part of
  # an application deployment and involves running a persistent service.
  #
  # @api public
  # @since 5.0.0
  # @todo example
  module ServiceMixin
    # Mixin for application service resources.
    #
    # @see ServiceMixin
    module Resource
      # @!visibility private
      # @api private
      def self.included(klass)
        klass.class_exec do
          include Poise(parent: Chef::Resource::Application, parent_optional: true)
          actions(:enable, :disable, :restart)

          attribute(:path, kind_of: String, name_attribute: true)
          attribute(:service_name, kind_of: String, default: lazy { PoiseApplication::Utils.parse_service_name(path) })
          attribute(:user, kind_of: [String, Integer], default: lazy { parent ? parent.owner : 'root' })
        end
      end
    end

    # Mixin for application service providers.
    #
    # @see ServiceMixin
    module Provider
      # @!visibility private
      # @api private
      def self.included(klass)
        klass.class_exec { include Poise }
      end

      # Default enable action for application services.
      #
      # @api public
      # @return [void]
      def action_enable
        notify_if_service do
          service_resource.run_action(:enable)
        end
      end

      # Default disable action for application services.
      #
      # @api public
      # @return [void]
      def action_disable
        notify_if_service do
          service_resource.run_action(:disable)
        end
      end

      # Default restart action for application services.
      #
      # @api public
      # @return [void]
      def action_restart
        notify_if_service do
          service_resource.run_action(:restart)
        end
      end

      # @todo Add reload once poise-service supports it.

      private

      # Set the current resource as notified if the provided block updates the
      # service resource.
      #
      # @api public
      # @param block [Proc] Block to run.
      # @return [void]
      # @example
      #   notify_if_service do
      #     service_resource.run_action(:enable)
      #   end
      def notify_if_service(&block)
        service_resource.updated_by_last_action(false)
        block.call
        new_resource.updated_by_last_action(true) if service_resource.updated_by_last_action?
      end

      # Service resource for this application service. This returns a
      # poise_service resource that will not be added to the resource
      # collection. Override {#service_options} to set service resource
      # parameters.
      #
      # @api public
      # @return [Chef::Resource]
      # @example
      #   service_resource.run_action(:restart)
      def service_resource
        @service_resource ||= PoiseService::Resource.new(new_resource.name, run_context).tap do |r|
          # Set some defaults based on the resource and possibly the app.
          r.service_name(new_resource.service_name)
          r.directory(new_resource.path)
          r.user(new_resource.user)
          # Call the subclass hook for more specific settings.
          service_options(r)
        end
      end

      # Abstract hook to set parameters on {#service_resource} when it is
      # created. This is required to set at least `resource.command`.
      #
      # @api public
      # @param resource [Chef::Resource] Resource instance to set parameters on.
      # @return [void]
      # @example
      #   def service_options(resource)
      #     resource.command('myapp --serve')
      #   end
      def service_options(resource)
        raise NotImplementedError
      end
    end

    # Delegate to the correct mixin based on the type of class.
    #
    # @!visibility private
    # @api private
    def self.included(klass)
      super
      if klass < Chef::Resource
        klass.class_exec { include PoiseApplication::ServiceMixin::Resource}
      elsif klass < Chef::Provider
        klass.class_exec { include PoiseApplication::ServiceMixin::Provider}
      end
    end
  end
end
