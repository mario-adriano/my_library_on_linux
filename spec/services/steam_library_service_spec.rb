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

  describe 'Testing sorting' do
    let(:steam_seven_games_response) { File.open('./spec/fixtures/steam/steam_seven_games.json') }

    let(:wishlist_seven_response) { File.open('./spec/fixtures/wishlist/wishlistdata_seven_games.json') }

    let(:appdetails_native_response) { File.open('./spec/fixtures/appdetails/appdetails_linux.json') }
    let(:appdetails_001_response) { File.open('./spec/fixtures/appdetails/appdetails_001.json') }
    let(:appdetails_002_response) { File.open('./spec/fixtures/appdetails/appdetails_002.json') }
    let(:appdetails_003_response) { File.open('./spec/fixtures/appdetails/appdetails_003.json') }
    let(:appdetails_004_response) { File.open('./spec/fixtures/appdetails/appdetails_004.json') }
    let(:appdetails_005_response) { File.open('./spec/fixtures/appdetails/appdetails_005.json') }
    let(:appdetails_006_response) { File.open('./spec/fixtures/appdetails/appdetails_006.json') }
    let(:appdetails_007_response) { File.open('./spec/fixtures/appdetails/appdetails_007.json') }
    let(:appdetails_008_response) { File.open('./spec/fixtures/appdetails/appdetails_008.json') }
    let(:appdetails_009_response) { File.open('./spec/fixtures/appdetails/appdetails_009.json') }
    let(:appdetails_010_response) { File.open('./spec/fixtures/appdetails/appdetails_010.json') }
    let(:appdetails_011_response) { File.open('./spec/fixtures/appdetails/appdetails_011.json') }
    let(:appdetails_012_response) { File.open('./spec/fixtures/appdetails/appdetails_012.json') }

    let(:proton_platinum_platinum_response) { File.open('./spec/fixtures/protondb/proton_platinum_platinum.json') }
    let(:proton_platinum_gold_response) { File.open('./spec/fixtures/protondb/proton_platinum_gold.json') }
    let(:proton_gold_platinum_response) { File.open('./spec/fixtures/protondb/proton_gold_platinum.json') }
    let(:proton_gold_gold_response) { File.open('./spec/fixtures/protondb/proton_gold_gold.json') }
    let(:proton_gold_silver_response) { File.open('./spec/fixtures/protondb/proton_gold_silver.json') }
    let(:proton_silver_gold_response) { File.open('./spec/fixtures/protondb/proton_silver_gold.json') }
    let(:proton_silver_silver_response) { File.open('./spec/fixtures/protondb/proton_silver_silver.json') }
    let(:proton_silver_bronze_response) { File.open('./spec/fixtures/protondb/proton_silver_bronze.json') }
    let(:proton_bronze_silver_response) { File.open('./spec/fixtures/protondb/proton_bronze_silver.json') }
    let(:proton_bronze_bronze_response) { File.open('./spec/fixtures/protondb/proton_bronze_bronze.json') }
    let(:proton_borked_borked_response) { File.open('./spec/fixtures/protondb/proton_borked_borked.json') }
    let(:proton_unknown_unknown_response) { File.open('./spec/fixtures/protondb/proton_unknown_unknown.json') }

    let(:library_api) do
      "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_KEY']}&steamid=12345678912345678&include_appinfo=true&include_played_free_games=true&appids_filter=[]"
    end

    let(:wishlist_api) do
      'https://store.steampowered.com/wishlist/profiles/12345678912345678/wishlistdata/?p=0'
    end

    let(:store_steamwered) do
      'https://store.steampowered.com/api/appdetails?appids=12312100'
    end
    let(:store_steamwered001) do
      'https://store.steampowered.com/api/appdetails?appids=001'
    end
    let(:store_steamwered002) do
      'https://store.steampowered.com/api/appdetails?appids=002'
    end
    let(:store_steamwered003) do
      'https://store.steampowered.com/api/appdetails?appids=003'
    end
    let(:store_steamwered004) do
      'https://store.steampowered.com/api/appdetails?appids=004'
    end
    let(:store_steamwered005) do
      'https://store.steampowered.com/api/appdetails?appids=005'
    end
    let(:store_steamwered006) do
      'https://store.steampowered.com/api/appdetails?appids=006'
    end
    let(:store_steamwered007) do
      'https://store.steampowered.com/api/appdetails?appids=007'
    end
    let(:store_steamwered008) do
      'https://store.steampowered.com/api/appdetails?appids=008'
    end
    let(:store_steamwered009) do
      'https://store.steampowered.com/api/appdetails?appids=009'
    end
    let(:store_steamwered010) do
      'https://store.steampowered.com/api/appdetails?appids=010'
    end
    let(:store_steamwered011) do
      'https://store.steampowered.com/api/appdetails?appids=011'
    end
    let(:store_steamwered012) do
      'https://store.steampowered.com/api/appdetails?appids=012'
    end

    let(:platinum_platinum_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/001.json'
    end
    let(:platinum_gold_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/002.json'
    end
    let(:gold_platinum_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/003.json'
    end
    let(:gold_gold_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/004.json'
    end
    let(:gold_silver_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/005.json'
    end
    let(:silver_gold_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/006.json'
    end
    let(:silver_silver_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/007.json'
    end
    let(:silver_bronze_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/008.json'
    end
    let(:bronze_silver_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/009.json'
    end
    let(:bronze_bronze_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/010.json'
    end
    let(:borked_borked_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/011.json'
    end
    let(:unknown_unknown_protondb) do
      'https://www.protondb.com/api/v1/reports/summaries/012.json'
    end

    before do
      stub_request(:get, library_api)
        .to_return(status: 200, body: steam_seven_games_response)

      stub_request(:get, wishlist_api)
        .to_return(status: 200, body: wishlist_seven_response)

      stub_request(:get, store_steamwered)
        .to_return(status: 200, body: appdetails_native_response)

      stub_request(:get, store_steamwered001)
        .to_return(status: 200, body: appdetails_001_response)

      stub_request(:get, store_steamwered002)
        .to_return(status: 200, body: appdetails_002_response)

      stub_request(:get, store_steamwered003)
        .to_return(status: 200, body: appdetails_003_response)

      stub_request(:get, store_steamwered004)
        .to_return(status: 200, body: appdetails_004_response)

      stub_request(:get, store_steamwered005)
        .to_return(status: 200, body: appdetails_005_response)

      stub_request(:get, store_steamwered006)
        .to_return(status: 200, body: appdetails_006_response)

      stub_request(:get, store_steamwered007)
        .to_return(status: 200, body: appdetails_007_response)

      stub_request(:get, store_steamwered008)
        .to_return(status: 200, body: appdetails_008_response)

      stub_request(:get, store_steamwered009)
        .to_return(status: 200, body: appdetails_009_response)

      stub_request(:get, store_steamwered010)
        .to_return(status: 200, body: appdetails_010_response)

      stub_request(:get, store_steamwered011)
        .to_return(status: 200, body: appdetails_011_response)

      stub_request(:get, store_steamwered012)
        .to_return(status: 200, body: appdetails_012_response)

      stub_request(:get, platinum_platinum_protondb)
        .to_return(status: 200, body: proton_platinum_platinum_response)

      stub_request(:get, platinum_gold_protondb)
        .to_return(status: 200, body: proton_platinum_gold_response)

      stub_request(:get, gold_platinum_protondb)
        .to_return(status: 200, body: proton_gold_platinum_response)

      stub_request(:get, gold_gold_protondb)
        .to_return(status: 200, body: proton_gold_gold_response)

      stub_request(:get, gold_silver_protondb)
        .to_return(status: 200, body: proton_gold_silver_response)

      stub_request(:get, silver_gold_protondb)
        .to_return(status: 200, body: proton_silver_gold_response)

      stub_request(:get, silver_silver_protondb)
        .to_return(status: 200, body: proton_silver_silver_response)

      stub_request(:get, silver_bronze_protondb)
        .to_return(status: 200, body: proton_silver_bronze_response)

      stub_request(:get, bronze_silver_protondb)
        .to_return(status: 200, body: proton_bronze_silver_response)

      stub_request(:get, bronze_bronze_protondb)
        .to_return(status: 200, body: proton_bronze_bronze_response)

      stub_request(:get, borked_borked_protondb)
        .to_return(status: 200, body: proton_borked_borked_response)

      stub_request(:get, unknown_unknown_protondb)
        .to_return(status: 200, body: proton_unknown_unknown_response)
    end

    list_type_and_services.each do |list, service|
      it "Should return ordered #{list}" do
        games = service.new.call(SteamLibrary.new('checklist' => list,
                                                  'steam_id' => '12345678912345678'))

        expect(games[0].tier).to eql('native')
        expect(games[0].trending_tier).to eql('native')
        expect(games[1].tier).to eql('platinum')
        expect(games[1].trending_tier).to eql('platinum')
        expect(games[2].tier).to eql('platinum')
        expect(games[2].trending_tier).to eql('gold')
        expect(games[3].tier).to eql('gold')
        expect(games[3].trending_tier).to eql('platinum')
        expect(games[4].tier).to eql('gold')
        expect(games[4].trending_tier).to eql('gold')
        expect(games[5].tier).to eql('gold')
        expect(games[5].trending_tier).to eql('silver')
        expect(games[6].tier).to eql('silver')
        expect(games[6].trending_tier).to eql('gold')
        expect(games[7].tier).to eql('silver')
        expect(games[7].trending_tier).to eql('silver')
        expect(games[8].tier).to eql('silver')
        expect(games[8].trending_tier).to eql('bronze')
        expect(games[9].tier).to eql('bronze')
        expect(games[9].trending_tier).to eql('silver')
        expect(games[10].tier).to eql('bronze')
        expect(games[10].trending_tier).to eql('bronze')
        expect(games[11].tier).to eql('borked')
        expect(games[11].trending_tier).to eql('borked')
        expect(games[12].tier).to eql('unknown')
        expect(games[12].trending_tier).to eql('unknown')
      end
    end
  end
end
