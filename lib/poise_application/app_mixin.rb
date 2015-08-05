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
  module AppMixin
    include Poise::Utils::ResourceProviderMixin

    module Resource
      include Poise::Resource

      def app_state
        if parent
          parent.app_state
        else
          # If there isn't a parent, just track within the resource.
          @local_app_state ||= Mash.new
        end
      end

      def app_state_environment
        app_state[:environment] ||= Mash.new
      end

      module ClassMethods
        # @api private
        def included(klass)
          super
          klass.extend(ClassMethods)
          klass.poise_subresource(:application, true)
          klass.attribute(:path, kind_of: String, name_attribute: true)
        end
      end

      extend ClassMethods
    end

    module Provider
      include Poise::Provider
    end
  end
end
