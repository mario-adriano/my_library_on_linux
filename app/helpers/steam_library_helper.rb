module SteamLibraryHelper
  def row_color(tier)
    case tier
    when 'native'
      'native'
    when 'platinum'
      'platinum'
    when 'gold'
      'gold'
    when 'silver'
      'silver'
    when 'bronze'
      'bronze'
    when 'borked'
      'borked'
    else
      'unknown'
    end
  end

  def trending(game)
    if game.numeric_trending_tier_value > game.numeric_tier_value
      'fa-solid fa-arrow-trend-down'
    elsif game.numeric_trending_tier_value < game.numeric_tier_value
      'fa-solid fa-arrow-trend-up'
    else
      ''
    end
  end

  def games_pie_chart(games)
    colors = { 'native' => '#4da338', 'platinum' => 'rgb(180, 199, 220)', 'gold' => '#ffce41',
               'silver' => 'rgb(166, 166, 166)', 'bronze' => 'rgb(205, 127, 50)', 'borked' => '#bf5151',
               'unknown' => 'rgb(187, 179, 179)' }
    ordered_game = ordered_game(games)
    pie_chart(ordered_game,
              width: '250px',
              height: '250px',
              legend: false,
              donut: true,
              colors: ordered_game.map { |key, _value| colors[key] })
  end

  private

  def ordered_game(games)
    games.sort_by(&:numeric_tier_value)
         .group_by(&:tier)
         .map { |key, value| [key, value.size] }
  end
end
