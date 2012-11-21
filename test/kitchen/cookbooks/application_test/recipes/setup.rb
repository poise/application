case node.platform
  when 'ubuntu'
    %w{libxml2 libxml2-dev libxslt1-dev}.each do |pkg|
      package pkg do
        action :install
      end
    end
  when 'centos'
    %w{libxml2 libxml2-devel libxslt libxslt-devel}.each do |pkg|
      package pkg do
        action :install
      end
    end
end

node.set['rvm']['user_installs'] = [
  { 'user'          => 'vagrant',
    'default_ruby'  => 'ruby-1.9.2-p320',
    'rubies'        => [] 
  }
]
include_recipe "rvm::user"
