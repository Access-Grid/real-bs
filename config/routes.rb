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

    # Cred
    get "cred/list" => "api/creds#list"
    post "cred/save" => "api/creds#save"
    post "cred/update/:id" => "api/creds#update"
    post "cred/delete/:id" => "api/creds#delete"

    # CredTemplate
    get "credTemplate/list" => "api/cred_templates#list"
    post "credTemplate/save" => "api/cred_templates#save"
    post "credTemplate/update/:id" => "api/cred_templates#update"
    post "credTemplate/delete/:id" => "api/cred_templates#delete"

    # DataFormat / BinaryFormat (both map to CredentialFormat)
    get "dataFormat/list" => "api/data_formats#list"
    post "dataFormat/save" => "api/data_formats#save"
    post "dataFormat/update/:id" => "api/data_formats#update"
    post "dataFormat/delete/:id" => "api/data_formats#delete"
    get "binaryFormat/list" => "api/data_formats#list"
    post "binaryFormat/save" => "api/data_formats#save"
    post "binaryFormat/update/:id" => "api/data_formats#update"
    post "binaryFormat/delete/:id" => "api/data_formats#delete"

    # DataLayout / BasicDataLayout (both map to DataLayout)
    get "dataLayout/list" => "api/data_layouts#list"
    post "dataLayout/save" => "api/data_layouts#save"
    post "dataLayout/update/:id" => "api/data_layouts#update"
    post "dataLayout/delete/:id" => "api/data_layouts#delete"
    get "basicDataLayout/list" => "api/data_layouts#list"
    post "basicDataLayout/save" => "api/data_layouts#save"
    post "basicDataLayout/update/:id" => "api/data_layouts#update"
    post "basicDataLayout/delete/:id" => "api/data_layouts#delete"
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
