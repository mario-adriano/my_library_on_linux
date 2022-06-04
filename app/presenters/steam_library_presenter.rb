class SteamLibraryPresenter < SimpleDelegator
  Game.tiers.each do |key, _value|
    define_method :"percentage_of_#{key.pluralize}_with_character" do
      # result = instance_eval("percentage_of_#{key.pluralize}", __FILE__, __LINE__)
      result = send("percentage_of_#{key.pluralize}")
      result.to_s.concat('%')
    end
  end

  def percentage_of_playables_with_character
    percentage_of_playables.to_s.concat('%')
  end

  def game_or_games(value)
    value > 1 ? I18n.t('static_pages.show.games') : I18n.t('static_pages.show.game')
  end
end
