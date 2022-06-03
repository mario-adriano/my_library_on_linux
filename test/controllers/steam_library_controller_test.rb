require 'test_helper'

class MyLibrariesControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get steam_library_index_url
    assert_response :success
  end

  test 'should get show' do
    get steam_library_show_url
    assert_response :success
  end
end
