Rails.application.routes.draw do

  devise_for  :users,
  path: 'api/v1/user',
  controllers: {
    registrations: 'api/v1/user/registrations',
    sessions: 'api/v1/user/sessions',
    passwords: 'api/v1/user/passwords'
  },
  defaults: { format: :json }

    namespace :api, :defaults => {:format => :json} do
      namespace :v1 do
        get 'users/current', to:'users#show'
      end
    end

end
