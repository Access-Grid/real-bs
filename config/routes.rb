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
    get "terminate" => "api/authentication#terminate"
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

    # DoorAccessPriv (maps to AccessRuleSet)
    get "doorAccessPriv/list" => "api/door_access_privs#list"
    post "doorAccessPriv/save" => "api/door_access_privs#save"
    post "doorAccessPriv/update/:id" => "api/door_access_privs#update"
    post "doorAccessPriv/delete/:id" => "api/door_access_privs#delete"

    # Sched (maps to Schedule)
    get "sched/list" => "api/scheds#list"
    post "sched/save" => "api/scheds#save"
    post "sched/update/:id" => "api/scheds#update"
    post "sched/delete/:id" => "api/scheds#delete"

    # HolType (maps to HolidayType)
    get "holType/list" => "api/hol_types#list"
    post "holType/save" => "api/hol_types#save"
    post "holType/update/:id" => "api/hol_types#update"
    post "holType/delete/:id" => "api/hol_types#delete"

    # HolCal (maps to HolidayCalendar)
    get "holCal/list" => "api/hol_cals#list"
    post "holCal/save" => "api/hol_cals#save"
    post "holCal/update/:id" => "api/hol_cals#update"
    post "holCal/delete/:id" => "api/hol_cals#delete"

    # Hol (maps to Holiday)
    get "hol/list" => "api/hols#list"
    post "hol/save" => "api/hols#save"
    post "hol/update/:id" => "api/hols#update"
    post "hol/delete/:id" => "api/hols#delete"

    # Evt (maps to Event) -- read-only
    get "evt/list" => "api/evts#list"
    get "evt/show/:id" => "api/evts#show"

    # Dev: Actuator
    get "actuator/list" => "api/actuators#list"
    post "actuator/save" => "api/actuators#save"
    post "actuator/update/:id" => "api/actuators#update"
    post "actuator/delete/:id" => "api/actuators#delete"

    # Dev: NodeDev
    get "nodeDev/list" => "api/node_devs#list"
    post "nodeDev/save" => "api/node_devs#save"
    post "nodeDev/update/:id" => "api/node_devs#update"
    post "nodeDev/delete/:id" => "api/node_devs#delete"

    # EncryptionKey
    get "encryptionKey/list" => "api/encryption_keys#list"
    post "encryptionKey/save" => "api/encryption_keys#save"
    post "encryptionKey/update/:id" => "api/encryption_keys#update"
    post "encryptionKey/delete/:id" => "api/encryption_keys#delete"

    # DevActions (command endpoints)
    get "json/doorModeChange" => "api/dev_actions#door_mode_change"
    get "json/doorMomentaryUnlock" => "api/dev_actions#door_momentary_unlock"
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
