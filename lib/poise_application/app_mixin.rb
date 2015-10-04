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

require 'chef/mash'
require 'poise/provider'
require 'poise/resource'
require 'poise/utils'


module PoiseApplication
  # A helper mixin for application resources and providers. These are things
  # intended to be used as subresources of the `application` resource.
  #
  # @since 5.0.0
  module AppMixin
    include Poise::Utils::ResourceProviderMixin

    # A helper mixin for application resources.
    module Resource
      include Poise::Resource

      # Set the parent type and optional flag.
      poise_subresource(:application, true)

      # @!attribute path
      #   Base path for the application.
      #   @return [String]
      attribute(:path, kind_of: String, name_attribute: true)

      # A delegator for accessing the application state. If no application
      # parent is found, the state will be tracked internally within the
      # resource.
      #
      # @return [Hash<Symbol, Object>]
      def app_state
        if parent
          parent.app_state
        else
          # If there isn't a parent, just track within the resource.
          @local_app_state ||= Mash.new
        end
      end

      # Environment variables stored in the application state.
      #
      # @return [Hash<String, String>]
      def app_state_environment
        app_state[:environment] ||= Mash.new
      end
    end

    module Provider
      include Poise::Provider
    end
  end
end
