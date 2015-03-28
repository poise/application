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
require 'poise_service/service_mixin'
require 'poise_service/utils'

require 'poise_application/utils'


module PoiseApplication
  # Mixin for application services. This is any resource that will be part of
  # an application deployment and involves running a persistent service.
  #
  # @api public
  # @since 5.0.0
  # @example
  #   module MyApp
  #     class Resource < Chef::Resource
  #       include Poise
  #       provides(:my_app)
  #       include PoiseApplication::ServiceMixin
  #     end
  #
  #     class Provider < Chef::Provider
  #       include Poise
  #       provides(:my_app)
  #       include PoiseApplication::ServiceMixin
  #
  #       def action_enable
  #         notifying_block do
  #           template '/etc/myapp.conf' do
  #             # ...
  #           end
  #         end
  #         super
  #       end
  #
  #       def service_options(r)
  #         super
  #         r.command('myapp --serve')
  #       end
  #     end
  #   end
  module ServiceMixin
    # Mixin for application service resources.
    #
    # @see ServiceMixin
    module Resource
      # @api private
      def self.included(klass)
        klass.class_exec do
          include PoiseService::ServiceMixin::Resource
          poise_subresource(Chef::Resource::Application, true)

          attribute(:path, kind_of: String, name_attribute: true)
          # Redefines from the PoiseService version so we get a better default.
          attribute(:service_name, kind_of: String, default: lazy { PoiseService::Utils.parse_service_name(path) })
          attribute(:user, kind_of: [String, Integer], default: lazy { parent ? parent.owner : 'root' })
        end
      end
    end

    # Mixin for application service providers.
    #
    # @see ServiceMixin
    module Provider
      # @api private
      def self.included(klass)
        klass.class_exec do
          include PoiseService::ServiceMixin::Provider
        end
      end

      private

      # Abstract hook to set parameters on {#service_resource} when it is
      # created. This is required to set at least `resource.command`.
      #
      # @api public
      # @param resource [Chef::Resource] Resource instance to set parameters on.
      # @return [void]
      # @example
      #   def service_options(resource)
      #     super
      #     resource.command('myapp --serve')
      #   end
      def service_options(resource)
        r.directory(new_resource.path)
        r.user(new_resource.user)
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
