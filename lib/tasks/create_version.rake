task :create_version do
  desc 'create VERSION.'

  version_file = "#{Rails.root}/config/initializers/version.rb"
  git_tag = `git describe --abbrev=0 --tags`
  version_string = "class #{Rails.application.class.module_parent_name}::Application\n"
  version_string += "  VERSION = #{git_tag}"
  version_string += 'end'
  File.open(version_file, 'w') { |f| f.print(version_string) }
  $stderr.print(version_string)
end
