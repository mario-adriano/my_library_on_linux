# frozen_string_literal: true

# This class assembles the library games list
class SteamLibraryController < ApplicationController
  before_action :set_locale
  def index
    @steam_library = SteamLibrary.new
  end

  def show
    @steam_library = SteamLibrary.new(steam_library_params)
    if @steam_library.valid?
      @steam_library.games = load_service
      redirect_to steam_library_error_path if zero_game_count?
    else
      show_error_message_and_change_page(I18n.t('steam_library.errors.invalid_value'), steam_library_path)
    end
  rescue LibraryProtonError::Error::ResquestError
    show_error_message_and_change_page(I18n.t('steam_library.errors.an_error_occurred'), steam_library_path)
  end

  private

  def steam_library_params
    params.require(:steam_library).permit(:steam_id, :checklist).to_unsafe_hash
  end

  def load_service
    if @steam_library.checklist.eql?(SteamLibrary.checklist_wishlist)
      SteamLibraryService::ShowWishListService.new.call(@steam_library)
    else
      SteamLibraryService::ShowLibraryService.new.call(@steam_library)
    end
  end

  def zero_game_count?
    @steam_library.total_games.zero?
  end

  def show_error_message_and_change_page(msg, page)
    flash[:danger] = msg
    redirect_to page
  end

  def set_locale
    session[:locale] = params[:locale] if params[:locale].present?
    I18n.locale = session[:locale] || I18n.default_locale
  end
end
