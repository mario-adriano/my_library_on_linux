Rails.application.routes.draw do
  root 'steam_library#index'

  get 'steam_library/show', to: 'steam_library#show', as: 'steam_library_show'
  get 'steam_library/index', to: 'steam_library#index', as: 'steam_library'
  get 'steam_library/error', as: 'steam_library_error'

  # This route must be the last line of the file
  match '*path', to: redirect('/'), via: :all if Rails.env.production?
end
