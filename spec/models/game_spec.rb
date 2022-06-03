require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe Game, type: :model do
  context 'validate all fields' do
    it 'Must be valid' do
      game = Game.new(name: 'Bioshock 4', appid: '11112025')
      expect(game).to be_valid
    end
  end

  context 'Validating appid' do
    it 'Must not be valid' do
      game = Fabricate.build(:game, appid: '')
      expect(game).to_not be_valid
      expect(game.errors[:appid]).to(include("can't be blank"))
    end

    before { described_class.create!(name: 'Bioshock 4', appid: '12312100') }
    it 'appid should be unique' do
      game = Fabricate.build(:game)
      expect(game).to_not be_valid
      expect(game.errors[:appid]).to(include(I18n.t('games.errors.appid_must_be_unique')))
    end
  end

  context 'Validating name' do
    it 'Must not be valid' do
      game = Fabricate.build(:game, name: '')
      expect(game).to_not be_valid
      expect(game.errors[:name]).to(include("can't be blank"))
    end
  end

  context 'Enum unknown tier' do
    it 'When creating the game, the tier should be unknown by default' do
      game = Game.new(name: 'Bioshock 4', appid: '11112025')
      expect(game.tier).to eql('unknown')
    end
  end

  context 'Enum unknown trending tier' do
    it 'When creating the game, the trending tier should be unknown by default' do
      game = Game.new(name: 'Bioshock 4', appid: '11112025')
      expect(game.trending_tier).to eql('unknown')
    end
  end

  context 'Testing need_to_update method in game windows' do
    it 'Should return true for games with the same tier within 5 days' do
      game = Fabricate.build(:game, id: 1, tier: :gold, trending_tier: :gold, updated_at: Date.today - 5.days)
      expect(game.need_to_update?).to be true
    end

    it 'Should return false for games with the same tier within 4 days' do
      game = Fabricate.build(:game, id: 1, tier: :gold, trending_tier: :gold, updated_at: Date.today - 4.days)
      expect(game.need_to_update?).to be false
    end

    it 'Should return true for games with the different tier within 3 days' do
      game = Fabricate.build(:game, id: 1, tier: :platinum, trending_tier: :gold,
                                    updated_at: Date.today - 3.days)
      expect(game.need_to_update?).to be true
    end

    it 'Should return false for games with the different tier within 2 days' do
      game = Fabricate.build(:game, id: 1, tier: :platinum, trending_tier: :gold,
                                    updated_at: Date.today - 2.days)
      expect(game.need_to_update?).to be false
    end
  end

  context 'Testing need_to_update method in native game' do
    it 'Should return true for games with the same tier within 2 weeks and 1 day' do
      game = Fabricate.build(:game, id: 1, tier: :native, updated_at: Date.today - 2.weeks - 1.days)
      expect(game.need_to_update?).to be true
    end

    it 'Should return false for games with the same tier within 2 weeks' do
      game = Fabricate.build(:game, id: 1, tier: :native, updated_at: Date.today - 2.weeks)
      expect(game.need_to_update?).to be false
    end
  end

  context 'When passed a tier enum value, it should return a corresponding string' do
    expected_values = { native: 'native', platinum: 'platinum', gold: 'gold', silver: 'silver', bronze: 'bronze',
                        borked: 'borked', unknown: 'unknown', invalid_symbol: 'unknown' }

    expected_values.each do |val, expected|
      it "When passing a tier with a #{val} symbol it must be #{expected}" do
        game = Fabricate.build(:game, tier: val)
        expect(game.tier).to eql(expected)
      end
    end
  end

  context 'When passed a trending tier enum value, it should return a corresponding string' do
    expected_values = { native: 'native', platinum: 'platinum', gold: 'gold', silver: 'silver', bronze: 'bronze',
                        borked: 'borked', unknown: 'unknown', invalid_symbol: 'unknown' }

    expected_values.each do |val, expected|
      it "When passing a tier with a #{val} symbol it must be #{expected}" do
        game = Fabricate.build(:game, trending_tier: val)
        expect(game.trending_tier).to eql(expected)
      end
    end
  end

  context 'when passed a tier enum value, it should return a corresponding integer' do
    expected_values = { native: 1, platinum: 2, gold: 3, silver: 4, bronze: 5, borked: 6, unknown: 7,
                        invalid_symbol: 7 }

    expected_values.each do |val, expected|
      it "#{val} tier must have the value #{expected}" do
        game = Fabricate.build(:game, tier: val)
        expect(game.numeric_tier_value).to eql(expected)
      end
    end
  end

  context 'when passed a trending tier enum value, it should return a corresponding integer' do
    expected_values = { native: 1, platinum: 2, gold: 3, silver: 4, bronze: 5, borked: 6, unknown: 7,
                        invalid_symbol: 7 }

    expected_values.each do |val, expected|
      it "#{val} trending tier must have the value #{expected}" do
        game = Fabricate.build(:game, trending_tier: val)
        expect(game.numeric_trending_tier_value).to eql(expected)
      end
    end
  end
end
