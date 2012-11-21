Given /^a new server$/ do
end

Then /^the "?(.+?)"? directory should exist$/ do |dir_name|
  @dir_name = dir_name
  assert File.directory?(dir_name), "File.directory?(#{dir_name}) = #{File.directory?(dir_name)}"
end

Then /^the "?(.+?)"? file should exist$/ do |file_name|
  @file_name = file_name
  assert File.file?(file_name)
end

Then /^it should be owned by (.+?) with group (.+?)$/ do |owner, group|
  # TODO
end

Then /^"?(.+?)"? should be a symlink to "?(.+?)"$/ do |link, target|
  assert File.symlink?(link)
  assert_equal target, File.readlink(link)
end

Then /^it should contain a line matching "(.+?)"$/ do |regexp|
  content = File.open(@file_name).read
  re = Regexp.new("^#{regexp}$")
  assert content =~ re
end
