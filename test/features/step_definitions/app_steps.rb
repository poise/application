Given /^a new server$/ do
end

Then /^the "?(.+?)"? directory should exist$/ do |dir_name|
  @dir_name = dir_name
  assert File.directory?(dir_name), "File.directory?(#{dir_name}) = #{File.directory?(dir_name)}"
end

Then /^"?(.+?)"? should be a symlink to "?(.+?)"$/ do |link, target|
  assert File.symlink?(link)
  assert_equal target, File.readlink(link)
end
