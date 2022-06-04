require 'rails_helper'

RSpec.describe GamePresenter, type: :presenter do
  let(:presenter) do
    GamePresenter.new(Game.new(appid: '12312100', name: 'Half-Life 3', tier: :gold, trending_tier: :gold))
  end

  describe 'Protondb link' do
    it 'Must show protondb link with appid' do
      expect(presenter.protondb_url).to eql('https://www.protondb.com/app/12312100')
    end
  end
end
