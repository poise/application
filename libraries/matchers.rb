if defined?(ChefSpec)

  def deploy_application(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:application, :deploy, resource)
  end

  def force_deploy_application(resource)
    ChefSpec::Matchers::ResourceMatcher.new(:application, :force_deploy, resource)
  end

end
