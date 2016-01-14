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

require 'poise/utils'

require 'poise_application/app_mixin'


module PoiseApplication
  # A helper mixin for `file`-like resources to make them take application
  # resource data. Relative paths are expanded against the application path and
  # the app owner/group are the default user/group for the resource.
  #
  # @api private
  # @since 5.1.0
  module AppFileMixin
    include Poise::Utils::ResourceProviderMixin

    module Resource
      include PoiseApplication::AppMixin

      def initialize(*)
        super
        # So our lazy default below can work. Not needed on 12.7+.
        remove_instance_variable(:@path) if instance_variable_defined?(:@path)
      end

      # @!attribute path
      #   Override the default path to be relative to the app path.
      #   @return [String]
      attribute(:path, kind_of: String, default: lazy { parent ? ::File.expand_path(name, parent.path) : name })

      # @!attribute group
      #   Override the default group to be the app group if unspecified.
      #   @return [String, Integer]
      attribute(:group, kind_of: [String, Integer, NilClass], default: lazy { parent && parent.group })

      # @!attribute user
      #   Override the default user to be the app owner if unspecified.
      #   @return [String, Integer]
      attribute(:user, kind_of: [String, Integer, NilClass], default: lazy { parent && parent.owner })
    end

    module Provider
      include PoiseApplication::AppMixin
    end
  end
end
