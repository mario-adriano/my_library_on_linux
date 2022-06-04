require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe SteamLibrary, type: :model do
  context 'Validate all fields' do
    it 'Must be valid with checklist library' do
      steam_library = SteamLibrary.new('checklist' => 'library', 'steam_id' => '12345678912345678')
      expect(steam_library).to be_valid
    end

    it 'Must be valid with checklist wishlist' do
      steam_library = SteamLibrary.new('checklist' => 'wishlist', 'steam_id' => '12345678912345678')
      expect(steam_library).to be_valid
    end
  end

  context 'Validating steam_id' do
    it 'Empty steam_id must not be valid' do
      steam_library = SteamLibrary.new('checklist' => 'library', 'steam_id' => '')
      expect(steam_library).to_not be_valid
      expect(steam_library.errors[:steam_id]).to(contain_exactly('is not a number',
                                                                 'is the wrong length (should be 17 characters)'))
    end

    it 'steam_id longer than 17 characters must not be valid' do
      steam_library = SteamLibrary.new('checklist' => 'library', 'steam_id' => '123456789123456789')
      expect(steam_library).to_not be_valid
      expect(steam_library.errors[:steam_id]).to(contain_exactly('is the wrong length (should be 17 characters)'))
    end

    it 'checklist must included in the list' do
      steam_library = SteamLibrary.new('checklist' => '', 'steam_id' => '12345678912345678')
      expect(steam_library).to_not be_valid
      expect(steam_library.errors[:checklist]).to(include('is not included in the list'))
    end
  end

  context 'Testing checklist return' do
    it "Should return 'wishlist' in checklist_wishlist method" do
      expect(SteamLibrary.checklist_wishlist).to eql('wishlist')
    end

    it "Should return 'library' in checklist_library method" do
      expect(SteamLibrary.checklist_library).to eql('library')
    end
  end

  context 'Test change_list method' do
    it "Should return 'wishlist' when checklist is 'library'" do
      steam_library = SteamLibrary.new('checklist' => 'library', 'steam_id' => '12345678912345678')
      expect(steam_library.change_list).to eql('wishlist')
    end

    it "Should return 'library' when checklist is 'wishlist'" do
      steam_library = SteamLibrary.new('checklist' => 'wishlist', 'steam_id' => '12345678912345678')
      expect(steam_library.change_list).to eql('library')
    end
  end

  context 'Testing persisted method' do
    it "Should return 'false'" do
      steam_library = SteamLibrary.new('checklist' => 'library', 'steam_id' => '12345678912345678')
      expect(steam_library.persisted?).to be false
    end
  end

  context 'Test total_games method' do
    it "Should return '2'" do
      steam_library = SteamLibrary.new('games' => [Game.new(name: 'Half-Life 3', appid: '12312100'),
                                                   Game.new(name: 'Portal 3', appid: '12312099')])
      expect(steam_library.total_games).to eql(2)
    end
  end

  context 'Test count and percentage with tier' do
    Game.tiers.each do |key, _value|
      no_current_status = Game.tiers.reject { |tier| tier == key.to_s }.first[0]
      steam_library = SteamLibrary.new('games' => [Game.new(name: 'Half-Life 3', appid: '12312100', tier: key,
                                                            trending_tier: key),
                                                   Game.new(name: 'Portal 3', appid: '12312099', tier: key,
                                                            trending_tier: key),
                                                   Game.new(name: 'FIFA 50', appid: '12312299',
                                                            tier: no_current_status,
                                                            trending_tier: no_current_status)])

      it "Should return '2' with #{key}_count" do
        expect(steam_library.send("#{key}_count")).to eql(2)
      end

      it "Should return '66.67' with percentage_of_#{key.pluralize}" do
        expect(steam_library.send("percentage_of_#{key.pluralize}")).to eql(66.67)
      end
    end
  end

  context 'Test count and percentage of playables' do
    steam_library = SteamLibrary.new('games' => [Game.new(name: 'Half-Life 3', appid: '12312100', tier: :native,
                                                          trending_tier: :native),
                                                 Game.new(name: 'Portal 3', appid: '12312101', tier: :platinum,
                                                          trending_tier: :platinum),
                                                 Game.new(name: 'FIFA 50', appid: '12312102', tier: :gold,
                                                          trending_tier: :gold),
                                                 Game.new(name: 'Chrono Trigger 2', appid: '12312103', tier: :silver,
                                                          trending_tier: :silver),
                                                 Game.new(name: 'Super Star Soccer 2', appid: '12312104',
                                                          tier: :bronze, trending_tier: :bronze),
                                                 Game.new(name: 'Final Fight 4', appid: '12312105', tier: :borked,
                                                          trending_tier: :borked),
                                                 Game.new(name: 'Rock & Roll Racing 2', appid: '12312106',
                                                          tier: :unknown, trending_tier: :unknown)])

    it "Should return '3' with playable_count" do
      expect(steam_library.playable_count).to eql(3)
    end

    it "Should return '42.86' with percentage_of_playables" do
      expect(steam_library.percentage_of_playables).to eql(42.86)
    end
  end
end
