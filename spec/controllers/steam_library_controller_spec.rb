require 'webmock/rspec'
require 'rails_helper'

# rubocop:disable Metrics/BlockLength
RSpec.describe SteamLibraryController, type: :controller do
  lists = %w[library wishlist]

  let(:library_api) do
    "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_KEY']}&steamid=12345678912345678&include_appinfo=true&include_played_free_games=true&appids_filter=[]"
  end
  let(:store_steamwered) do
    'https://store.steampowered.com/api/appdetails?appids=12312100'
  end
  let(:wishlist_api) do
    'https://store.steampowered.com/wishlist/profiles/12345678912345678/wishlistdata/?p=0'
  end
  let(:store_steamwered_portal) do
    'https://store.steampowered.com/api/appdetails?appids=12312099'
  end
  let(:half_life_protondb) do
    'https://www.protondb.com/api/v1/reports/summaries/12312100.json'
  end

  let(:response_body) { File.open('./spec/fixtures/steam/steam.json') }
  let(:wishlist_response_body) { File.open('./spec/fixtures/wishlist/wishlistdata.json') }
  let(:json_half_life) { File.open('./spec/fixtures/protondb/proton_silver_silver.json') }
  let(:half_life_appdetails) { File.open('./spec/fixtures/appdetails/appdetails_windows.json') }

  describe 'GET #show' do
    before do
      stub_request(:get, library_api)
        .to_return(status: 200, body: response_body)

      stub_request(:get, wishlist_api)
        .to_return(status: 200, body: wishlist_response_body)

      stub_request(:get, half_life_protondb)
        .to_return(status: 200, body: json_half_life)

      stub_request(:get, store_steamwered)
        .to_return(status: 200, body: half_life_appdetails)
    end

    lists.each do |list|
      it 'returns http success' do
        get :show, params: { 'steam_library' => { 'checklist' => list, 'steam_id' => '12345678912345678' } }
        expect(response).to have_http_status(200)
      end

      it 'renders show' do
        get :show, params: { 'steam_library' => { 'checklist' => list, 'steam_id' => '12345678912345678' } }
        expect(response).to render_template(:show)
      end
    end
  end

  describe 'When steam_id is wrong' do
    lists.each do |list|
      it 'renders index' do
        get :show, params: { 'steam_library' => { 'checklist' => list, 'steam_id' => '123abc' } }

        expect(response).to redirect_to(steam_library_path)
      end
    end
  end

  describe 'When steam_id return is empty' do
    let(:empty_response_body) { File.open('./spec/fixtures/steam/empty_steam.json') }
    let(:empty_wishlist_response_body) { File.open('./spec/fixtures/wishlist/empty_wishlistdata.json') }

    lists.each do |list|
      it 'renders error' do
        stub_request(:get, library_api)
          .to_return(status: 200, body: empty_response_body)

        stub_request(:get, wishlist_api)
          .to_return(status: 200, body: empty_wishlist_response_body)

        get :show, params: { 'steam_library' => { 'checklist' => list, 'steam_id' => '12345678912345678' } }

        expect(response).to redirect_to(steam_library_error_path)
      end
    end
  end
end
