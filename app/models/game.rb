# frozen_string_literal: true

# == Schema Information
#
# Table name: games
#
#  id                :integer          not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  name              :string           not null
#  appid             :string           not null
#  tier              :string           not null
#  trending_tier     :string           not null
#
class Game < ApplicationRecord
  enum_tier = { native: 1, platinum: 2, gold: 3, silver: 4, bronze: 5, borked: 6, unknown: 7 }
  enum tier: enum_tier, _default: :unknown, _suffix: true
  enum trending_tier: enum_tier, _default: :unknown, _suffix: true

  validates :appid, uniqueness: { message: I18n.t('games.errors.appid_must_be_unique') }, presence: true
  validates :name, presence: true
  validates :tier, presence: true
  validates :trending_tier, presence: true

  scope :find_by_appids_and_order_by_tier, ->(appids) { where(appid: appids).order(:tier, :trending_tier) }

  NATIVE = 'native'

  def need_to_update?
    native_game_not_updated? || windows_game_not_updated?
  end

  def numeric_tier_value
    self.class.tiers[tier]
  end

  def numeric_trending_tier_value
    self.class.trending_tiers[trending_tier]
  end

  def tier=(value)
    super value || Game.tiers[:unknown]
  rescue StandardError
    super Game.tiers[:unknown]
  end

  def trending_tier=(value)
    super value || Game.trending_tiers[:unknown]
  rescue StandardError
    super Game.trending_tiers[:unknown]
  end

  private

  def native_game_not_updated?
    !windows_game? && (updated_at <= (Date.today - 2.weeks))
  end

  def windows_game_not_updated?
    if tier != trending_tier
      windows_game? && (updated_at <= (Date.today - 2.days))
    else
      windows_game? && (updated_at <= (Date.today - 4.days))
    end
  end

  def windows_game?
    id.present? && updated_at.present? && NATIVE != tier
  end
end
