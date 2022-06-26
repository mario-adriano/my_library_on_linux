namespace :version do
  desc 'create VERSION.'
  task create: :environment do
    version = ARGV[0]
    version_file = "#{Rails.root}/config/initializers/version.rb"
    file = []
    file.push("class #{Rails.application.class.module_parent_name}::Application")
    file.push("  VERSION = '#{version.strip}'.freeze")
    file.push('end')
    formatted_file = file.join("\n")
    File.open(version_file, 'w') { |f| f.print(formatted_file) }
    $stderr.print(formatted_file)
  end
end
