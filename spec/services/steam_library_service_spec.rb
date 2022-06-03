require 'webmock/rspec'
require 'rails_helper'

# rubocop:disable Metrics/BlockLength
# rubocop:disable Style/CombinableLoops
RSpec.describe SteamLibraryService::ShowLibraryService, type: :service do
  list_type_and_services = { SteamLibrary.checklist_library => SteamLibraryService::ShowLibraryService,
                             SteamLibrary.checklist_wishlist => SteamLibraryService::ShowWishListService }

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

  let(:response_body) { File.open('./spec/fixtures/steam/steam.json') }
  let(:response_body_with_two_games) { File.open('./spec/fixtures/steam/steam_two_games.json') }
  let(:wishlist_response_body) { File.open('./spec/fixtures/wishlist/wishlistdata.json') }
  let(:wishlist_response_body_with_two_games) { File.open('./spec/fixtures/wishlist/wishlistdata_two_games.json') }
  let(:portal_appdetails) { File.open('./spec/fixtures/appdetails/appdetails_linux _portal_3.json') }

  describe 'Native game' do
    let(:half_life_appdetails) { File.open('./spec/fixtures/appdetails/appdetails_linux.json') }
    let(:two_weeks_ago) { Date.today - 2.weeks }
    let(:two_weeks_and_one_day) { Date.today - (2.weeks - 1.days) }
    let(:updated_games) do
      [Fabricate(:game, name: 'Half-Life 3', appid: '12312100', tier: :native, trending_tier: :native,
                        updated_at: two_weeks_ago, created_at: two_weeks_ago)]
    end
    let(:games_not_updated) do
      [Fabricate(:game, name: 'Half-Life 3', appid: '12312100', tier: :native, trending_tier: :native,
                        updated_at: two_weeks_and_one_day, created_at: two_weeks_and_one_day)]
    end

    before do
      stub_request(:get, library_api)
        .to_return(status: 200, body: response_body)

      stub_request(:get, wishlist_api)
        .to_return(status: 200, body: wishlist_response_body)

      stub_request(:get, store_steamwered)
        .to_return(status: 200, body: half_life_appdetails)
    end

    list_type_and_services.each do |list, service|
      it "Must not update native game within four weeks of #{list}" do
        allow_any_instance_of(service).to receive(:load_library)
          .and_return(updated_games)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.first.tier).to eql('native')
        expect(games.first.updated_at).to eql(two_weeks_ago.to_time)
      end
    end

    list_type_and_services.each do |list, service|
      it "Must update native game above two weeks of #{list}" do
        allow_any_instance_of(service).to receive(:load_library)
          .and_return(games_not_updated)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.first.tier).to eql('native')
        expect(games.first.updated_at).to be > two_weeks_and_one_day
      end
    end

    list_type_and_services.each do |list, service|
      it "Must update the #{list} quantity to 2" do
        stub_request(:get, library_api)
          .to_return(status: 200, body: response_body_with_two_games)

        stub_request(:get, wishlist_api)
          .to_return(status: 200, body: wishlist_response_body_with_two_games)

        stub_request(:get, store_steamwered_portal)
          .to_return(status: 200, body: portal_appdetails)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.count).to eql(2)
      end
    end
  end

  let(:half_life_appdetails) { File.open('./spec/fixtures/appdetails/appdetails_windows.json') }
  let(:half_life_protondb) do
    'https://www.protondb.com/api/v1/reports/summaries/12312100.json'
  end
  let(:portal_protondb) do
    'https://www.protondb.com/api/v1/reports/summaries/12312099.json'
  end
  describe 'Windows game with the same tier' do
    let(:json_half_life) { File.open('./spec/fixtures/protondb/proton_silver_silver.json') }
    let(:json_portal) { File.open('./spec/fixtures/protondb/proton_silver_silver.json') }
    let(:portal_appdetails) { File.open('./spec/fixtures/appdetails/appdetails_windows_portal_3.json') }

    let(:four_days_ago) { Date.today - 4.days }
    let(:five_days_ago) { Date.today - 5.days }
    let(:updated_games) do
      [Fabricate(:game, name: 'Half-Life 3', appid: '12312100', tier: :silver, trending_tier: :silver,
                        updated_at: four_days_ago, created_at: four_days_ago)]
    end
    let(:games_not_updated) do
      [Fabricate(:game, name: 'Half-Life 3', appid: '12312100', tier: :bronze, trending_tier: :bronze,
                        updated_at: five_days_ago, created_at: five_days_ago)]
    end

    before do
      stub_request(:get, library_api)
        .to_return(status: 200, body: response_body)

      stub_request(:get, wishlist_api)
        .to_return(status: 200, body: wishlist_response_body)

      stub_request(:get, store_steamwered)
        .to_return(status: 200, body: half_life_appdetails)

      stub_request(:get, half_life_protondb)
        .to_return(status: 200, body: json_half_life)
    end

    list_type_and_services.each do |list, service|
      it "Must not update windows game within four days with the same #{list} tier" do
        allow_any_instance_of(service).to receive(:load_library)
          .and_return(updated_games)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.first.tier).to eql('silver')
        expect(games.first.updated_at).to eql(four_days_ago.to_time)
      end
    end

    list_type_and_services.each do |list, service|
      it "Must update windows game above four days with the same #{list} tier" do
        allow_any_instance_of(service).to receive(:load_library)
          .and_return(games_not_updated)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.first.tier).to eql('silver')
        expect(games.first.trending_tier).to eql('silver')
        expect(games.first.updated_at).to be > five_days_ago
      end
    end

    list_type_and_services.each do |list, service|
      it "Must update Windows game with same tier for #{list} value to 2" do
        stub_request(:get, library_api)
          .to_return(status: 200, body: response_body_with_two_games)

        stub_request(:get, wishlist_api)
          .to_return(status: 200, body: wishlist_response_body_with_two_games)

        stub_request(:get, store_steamwered_portal)
          .to_return(status: 200, body: portal_appdetails)

        stub_request(:get, portal_protondb)
          .to_return(status: 200, body: json_portal)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.count).to eql(2)
      end
    end
  end

  describe 'Windows game with the different tier' do
    let(:json_half_life) { File.open('./spec/fixtures/protondb/proton_silver_gold.json') }
    let(:json_portal) { File.open('./spec/fixtures/protondb/proton_silver_gold.json') }

    let(:two_days_ago) { Date.today - 2.days }
    let(:three_days_ago) { Date.today - 3.days }
    let(:updated_games) do
      [Fabricate(:game, name: 'Half-Life 3', appid: '12312100', tier: :silver, trending_tier: :gold,
                        updated_at: two_days_ago, created_at: two_days_ago)]
    end
    let(:games_not_updated) do
      [Fabricate(:game, name: 'Half-Life 3', appid: '12312100', tier: :bronze, trending_tier: :silver,
                        updated_at: three_days_ago, created_at: three_days_ago)]
    end

    before do
      stub_request(:get, library_api)
        .to_return(status: 200, body: response_body)

      stub_request(:get, wishlist_api)
        .to_return(status: 200, body: wishlist_response_body)

      stub_request(:get, store_steamwered)
        .to_return(status: 200, body: half_life_appdetails)

      stub_request(:get, half_life_protondb)
        .to_return(status: 200, body: json_half_life)
    end

    list_type_and_services.each do |list, service|
      it "Must not update windows game within 2 days with the different #{list} tier" do
        allow_any_instance_of(SteamLibraryService::ShowLibraryService).to receive(:load_library)
          .and_return(updated_games)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.first.tier).to eql('silver')
        expect(games.first.trending_tier).to eql('gold')
        expect(games.first.updated_at).to eql(two_days_ago.to_time)
      end
    end

    list_type_and_services.each do |list, service|
      it "Must update windows game above two days with the different #{list} tier" do
        allow_any_instance_of(service).to receive(:load_library)
          .and_return(games_not_updated)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.first.tier).to eql('silver')
        expect(games.first.updated_at).to be > three_days_ago
      end
    end

    list_type_and_services.each do |list, service|
      it "Must update Windows game with different tier for #{list} value to 2" do
        stub_request(:get, library_api)
          .to_return(status: 200, body: response_body_with_two_games)

        stub_request(:get, wishlist_api)
          .to_return(status: 200, body: wishlist_response_body_with_two_games)

        stub_request(:get, store_steamwered_portal)
          .to_return(status: 200, body: portal_appdetails)

        stub_request(:get, portal_protondb)
          .to_return(status: 200, body: json_portal)

        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games.count).to eql(2)
      end
    end
  end
end
