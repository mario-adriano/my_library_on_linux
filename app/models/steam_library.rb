# frozen_string_literal: true

# rubocop:disable Style/Documentation

class SteamLibrary
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Model

  attr_accessor :games, :steam_id, :checklist

  VALID_CHECKLIST = %w[library wishlist].freeze

  validates :steam_id, length: { is: 17 }, numericality: { only_integer: true }
  validates :checklist, inclusion: { in: VALID_CHECKLIST }

  def initialize(values = {})
    @steam_id = values['steam_id']
    @games = values['games'] || []
    @checklist = values['checklist'] || 'library'
  end

  def persisted? = false

  def change_list
    if @checklist.eql?(SteamLibrary.checklist_library)
      SteamLibrary.checklist_wishlist
    else
      SteamLibrary.checklist_library
    end
  end

  def self.checklist_wishlist = 'wishlist'

  def self.checklist_library = 'library'

  def total_games = games.count

  def playable_count
    games.select { |game| game.tier == 'native' || game.tier == 'platinum' || game.tier == 'gold' }.length
  end

  def percentage_of_playables
    ((playable_count.to_f * 100) / total_games).round(2).truncate(2)
  end

  Game.tiers.each do |key, _value|
    define_method :"#{key}_count" do
      games.select { |game| game.tier == key }.length
    end

    define_method :"percentage_of_#{key.pluralize}" do
      count = send("#{key}_count")
      ((count.to_f * 100) / total_games).round(2).truncate(2)
    end
  end
end
