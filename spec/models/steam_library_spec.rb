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
end
