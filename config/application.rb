require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MyLibraryOnLinux
  STEAM_KEY = ENV['STEAM_KEY']
  class Application < Rails::Application
    config.time_zone = 'America/Sao_Paulo'
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.i18n.available_locales = %w[en pt-BR]
    config.i18n.default_locale = 'en'

    # config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')
    # config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/
  end
end
