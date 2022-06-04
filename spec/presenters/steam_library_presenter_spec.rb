require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe SteamLibraryPresenter, type: :presenter do
  let(:presenter) do
    SteamLibraryPresenter.new(SteamLibrary.new('games' => [Game.new(name: 'Half-Life 3', appid: '12312100',
                                                                    tier: :native, trending_tier: :native),
                                                           Game.new(name: 'Portal 3', appid: '12312101',
                                                                    tier: :platinum, trending_tier: :platinum),
                                                           Game.new(name: 'FIFA 50', appid: '12312102',
                                                                    tier: :gold, trending_tier: :gold),
                                                           Game.new(name: 'Chrono Trigger 2', appid: '12312103',
                                                                    tier: :silver, trending_tier: :silver),
                                                           Game.new(name: 'Super Star Soccer 2', appid: '12312104',
                                                                    tier: :bronze, trending_tier: :bronze),
                                                           Game.new(name: 'Final Fight 4', appid: '12312105',
                                                                    tier: :borked, trending_tier: :borked),
                                                           Game.new(name: 'Rock & Roll Racing 2', appid: '12312106',
                                                                    tier: :unknown, trending_tier: :unknown)]))
  end

  describe "Test percentage with '%'" do
    Game.tiers.each do |key, _value|
      it "Should return percentage with '%' in percentage_of_#{key}_with_character method " do
        expect(presenter.send("percentage_of_#{key.pluralize}_with_character")).to eql('14.29%')
      end
    end

    it "Should return '42.86%' with percentage_of_playables_with_character" do
      expect(presenter.percentage_of_playables_with_character).to eql('42.86%')
    end
  end

  it 'Should return plural with number of games greater than 1' do
    expect(presenter.game_or_games(2)).to eql(I18n.t('static_pages.show.games'))
  end

  it 'Should not return plural with number of games equal to 1' do
    expect(presenter.game_or_games(1)).to eql(I18n.t('static_pages.show.game'))
  end
end
