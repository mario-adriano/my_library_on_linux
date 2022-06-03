class GamePresenter < SimpleDelegator
  def protondb_url
    "https://www.protondb.com/app/#{appid}"
  end
end
