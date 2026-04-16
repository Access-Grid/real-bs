Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Z9/Flex Community API
  scope defaults: { format: :json } do
    post "authenticate" => "api/authentication#create"
    get "api/health" => "api/health#show"

    # Dev: Controller
    get "controller/list" => "api/controllers#list"
    post "controller/save" => "api/controllers#save"
    post "controller/update/:id" => "api/controllers#update"
    post "controller/delete/:id" => "api/controllers#delete"

    # Dev: Door
    get "door/list" => "api/doors#list"
    post "door/save" => "api/doors#save"
    post "door/update/:id" => "api/doors#update"
    post "door/delete/:id" => "api/doors#delete"

    # Dev: CredReader
    get "credReader/list" => "api/cred_readers#list"
    post "credReader/save" => "api/cred_readers#save"
    post "credReader/update/:id" => "api/cred_readers#update"
    post "credReader/delete/:id" => "api/cred_readers#delete"

    # Dev: Sensor
    get "sensor/list" => "api/sensors#list"
    post "sensor/save" => "api/sensors#save"
    post "sensor/update/:id" => "api/sensors#update"
    post "sensor/delete/:id" => "api/sensors#delete"
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
