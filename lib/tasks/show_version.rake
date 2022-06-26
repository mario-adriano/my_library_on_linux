namespace :version do
  desc 'show VERSION.'
  task show: :environment do

    warn(MyLibraryOnLinux::Application::VERSION)
  end
end
