task :create_version do
  desc 'create VERSION.'

  version_file = "#{Rails.root}/config/initializers/version.rb"
  git_tag = `git describe --abbrev=0 --tags`
  file = []
  file.push("class #{Rails.application.class.module_parent_name}::Application")
  file.push("  VERSION = '#{git_tag.strip}'.freeze")
  file.push('end')
  formatted_file = file.join("\n")
  File.open(version_file, 'w') { |f| f.print(formatted_file) }
  $stderr.print(formatted_file)
end
