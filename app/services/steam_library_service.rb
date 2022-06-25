# frozen_string_literal: true

# rubocop:disable Style/Documentation

module SteamLibraryService
  NATIVE = 'native'
  STEAM_DETAILS_GAME = 'https://store.steampowered.com/api/appdetails?'
  PROTONDB = 'https://www.protondb.com/api/v1/reports/summaries'

  class ShowLibraryService
    include SteamLibraryService

    STEAM_LIBRARY = 'https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?include_appinfo=true&include_played_free_games=true&appids_filter=[]'

    def call(steam_library)
      all_games_library_in_string = find_games_by_steam_id(steam_library.steam_id)
      save_games_with_tier(create_game_list(all_games_library_in_string))
    end

    private

    def find_games_by_steam_id(steam_id)
      response = Faraday.get(STEAM_LIBRARY, { key: MyLibraryOnLinux::STEAM_KEY, steamid: steam_id })
      raise_bad_response(response)
      response.body
    end

    def create_game_list(game_list)
      json = JSON.parse(game_list)
      game_parameters(json).try(:map) { |game| Game.new(game) }
    end

    def game_parameters(json)
      params = ActionController::Parameters.new(json)
      params.fetch(:response, {}).permit(games: %i[name appid]).to_unsafe_hash['games']
    end
  end

  class ShowWishListService
    include SteamLibraryService

    WISHLIST_STEAM = 'https://store.steampowered.com/wishlist/profiles'

    def call(steam_library)
      all_games_library_in_string = find_games_by_steam_id(steam_library.steam_id)
      save_games_with_tier(create_game_list(all_games_library_in_string))
    end

    private

    def find_games_by_steam_id(steam_id)
      response = Faraday.get "#{WISHLIST_STEAM}/#{steam_id}/wishlistdata/?p=0"
      raise_bad_response(response)
      response.body
    end

    def create_game_list(game_list)
      json = JSON.parse(game_list)
      json.select { |_key, value| value['type'].try(:upcase).eql? 'GAME' }.map do |game|
        Game.new(name: game[1]['name'], appid: game[0])
      end
    end
  end

  private

  def raise_bad_response(response)
    raise MyLibraryOnLinuxError::Error::ResquestError unless success?(response)
  end

  def success?(response)
    !(400..599).include?(response.status)
  end

  def save_games_with_tier(games)
    loaded_games = load_library(games)
    save_games(games_to_save(loaded_games, games))
    load_library(games)
  end

  def update_tier(game)
    add_native_level_for_linux_game?(game) ? [NATIVE, NATIVE] : add_level_for_execution_proton(game)
  end

  def add_native_level_for_linux_game?(game)
    response = Faraday.get STEAM_DETAILS_GAME, { appids: game.appid }
    raise_bad_response(response)
    json = success?(response) ? JSON.parse(response.body) : {}
    success_and_platform_linux?(json, game.appid)
  end

  def add_level_for_execution_proton(game)
    response = Faraday.get "#{PROTONDB}/#{game.appid}.json"
    json = success?(response) ? JSON.parse(response.body) : {}
    [json['tier'].try(:to_sym), json['trendingTier'].try(:to_sym)]
  end

  def success_and_platform_linux?(json, appid)
    json.any? && json[appid]['success'] && json[appid]['data']['platforms']['linux']
  end

  def games_to_save(loaded_games, games)
    if loaded_games.any?
      game_ready_to_save = return_unloaded_games(loaded_games, games)
      game_ready_to_save.concat(loaded_games.select(&:need_to_update?))
    else
      games
    end
  end

  def return_unloaded_games(loaded_games, games)
    games.reject do |game|
      loaded_games.select { |loaded_game| loaded_game.appid == game.appid }.any?
    end
  end

  def load_library(games)
    games = Game.find_by_appids_and_order_by_tier(games.try do
                                                    map(&:appid)
                                                  end)
    games.map { |game| GamePresenter.new(game) }
  end

  def save_games(games)
    games.try(:each) do |game|
      game.tier, game.trending_tier = update_tier(game)
      game.persisted? ? game.touch : game.save!
    end
  end
end
