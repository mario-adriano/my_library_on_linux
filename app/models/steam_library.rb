# frozen_string_literal: true

# This model represents the user's game library and does not persist in the database
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

  def persisted?() = false

  def change_list
    if @checklist.eql?(SteamLibrary.checklist_library)
      SteamLibrary.checklist_wishlist
    else
      SteamLibrary.checklist_library
    end
  end

  def self.checklist_wishlist
    'wishlist'
  end

  def self.checklist_library
    'library'
  end

  def total_games
    games.count
  end
end
