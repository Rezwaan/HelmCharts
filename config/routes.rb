require "sidekiq/web"
# require "sidekiq/pro/web"
# require "sidekiq-ent/web"

Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount Sidekiq::Web => "/sidekiq"

  namespace :admin, defaults: {format: :json} do
    devise_for :users, class_name: "Accounts::Account", controllers: {confirmations: "admin/confirmations", passwords: "admin/passwords"}
    resources :stores, only: %i[index show create update destroy] do
      member do
        post :activate_pos
        post :deactivate_pos
        post :working_times
        put :restore
      end
      collection do
        get :delivery_types
      end
    end
    resources :brands, only: %i[index create show update] do
      member do
        post :working_times
      end
    end
    resources :brand_categories, only: %i[index create show update]
    resources :accounts do
      member do
        put :roles
      end
      resources :account_roles, only: %i[create destroy] do
      end
    end
    resources :catalogs do
      collection do
        post :validate
      end

      member do
        post :publish
        post :assignments
        get :token
        get "preview/:token/:language" => "catalogs#preview", :as => :preview, :constraints => {token: /[^\/]+/}
      end
    end
    resources :sessions, only: %i[create] do
      collection do
        get :me
      end
    end
    resources :companies, except: %i[edit new]
    resources :integration_hosts, except: %i[edit new] do
      collection do
        get :integration_types
      end

      member do
        get :sync_stores
        get :sync_catalog_list
        get :sync_stores_working_hours
      end
    end
    resources :integration_catalogs, except: %i[edit new create] do
      member do
        get :sync_catalog
        post :link_to_catalog
      end
    end
    resources :integration_catalog_overrides, only: %i[index create show update destroy]
    resources :integration_stores, except: %i[edit new update] do
      member do
        post :link_to_store
      end
    end
    resources :app_versions, only: [:index, :show, :update] do
      collection do
        get :enum_options
        get :search
        put :bulk_update
      end
    end
    resources :countries, only: :index
    resources :prototypes
    resources :product_attributes
    resources :product_attribute_options, only: :index
    resources :tags
    resources :manufacturers
    resources :products
    resources :variants
    resources :notes, only: [:create, :index] do
      collection do
        get :note_types
      end
    end

    resources :orders, only: [:marshal] do
      member do
        get :marshal
      end
    end
    resources :assets, only: [] do
      collection do
        post :upload_signed_url
      end
    end
  end

  namespace :lite_app, defaults: {format: :json} do
    namespace :api do
      namespace :v1 do
        resources :sessions, only: %i[create]

        resources :devices, only: [] do
          collection do
            post :register
            get :me
            post :login
            post :logout
            patch "me" => "devices#update"
            put "me" => "devices#update"
          end
        end

        resources :orders, only: [:index, :show] do
          member do
            post :accept
            post :reject
            post :complete
            post :delivered
          end
          collection do
            get :active
            get :reject_reasons
          end
        end

        resources :tasks, only: [:index, :show] do
          member do
            post :perform
          end
        end

        resources :stores, only: [:index] do
          member do
            post :ready
            post :temporary_busy
          end
          collection do
            get :summary_report
          end
        end

        resources :store_items, only: [] do
          collection do
            get :list
            post :update_item
            get :out_of_stock
            post :update_bulk_items
          end
        end

        resources :tickets, defaults: {format: "json"}, only: [:create] do
          collection do
            get :ticket_type
          end
        end
      end
    end
  end

  namespace :zendesk do
    post "validate" => "controllers/zendesk#validate"
  end

  namespace :webhooks do
    namespace :pace do
      resources :orders, path: "", only: [] do
        collection do
          post :update_order
        end
      end
    end
  end

  get "/" => "statuses#liveness"
  get "/liveness" => "statuses#liveness"
  get "/readiness" => "statuses#readiness"
  get "/status" => "statuses#status"
end
