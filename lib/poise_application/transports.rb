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

module PoiseApplication
  module Transports
    module ClassMethods
      def transport_helper(name, resource_name=nil)
        define_method(name) do |&block|
          method_missing(resource_name || name, '', &block).tap do |r|
            subresources.insert(r)
          end
        end
      end

      def included(klass)
        super
        klass.extend ClassMethods
      end
    end

    extend ClassMethods

    transport_helper(:git, :poise_git)
  end
end
