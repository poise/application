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

require 'poise_application/transports'

class Chef
  class Resource::Application < Resource
    include Poise(container: true)
    include PoiseApplication::Transports
    default_action(:deploy)

    attribute(:path, kind_of: String, name_attribute: true)
    attribute(:environment_name, kind_of: String, default: lazy { node.chef_environment == '_default' ? 'production' : node.chef_environment })
    attribute(:owner, kind_of: String)
    attribute(:group, kind_of: String)
  end

  class Provider::Application < Provider
    include Poise

    def action_deploy
    end
  end
end
