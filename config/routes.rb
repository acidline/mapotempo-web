Mapotempo::Application.routes.draw do
  mount ApiRoot => '/api'

  devise_for :users
  get 'user_settings/:id' => 'users#edit_settings', :as => 'edit_user_settings'
  patch 'user_settings/:id' => 'users#update_settings', :as => 'update_user_settings'

  namespace :admin do
    resources :users
  end

  resources :tags

  resources :customers
  delete 'customer/job_matrix' => 'customers#stop_job_matrix'
  delete 'customer/job_optimizer' => 'customers#stop_job_optimizer'
  delete 'customer/job_geocoding' => 'customers#stop_job_geocoding'

  resources :vehicles

  resources :destinations
  get 'destination/import' => 'destinations#import'
  post 'destinations/upload' => 'destinations#upload', :as => 'destinations_import_models'
  delete 'destinations' => 'destinations#clear'
  patch 'destination/geocode' => 'destinations#geocode'
  patch 'destination/geocode_reverse' => 'destinations#geocode_reverse'
  if Mapotempo::Application.config.geocode_complete
    patch 'destination/geocode_complete' => 'destinations#geocode_complete'
  end

  resources :plannings do
    patch 'move'
    get 'refresh'
    patch 'switch'
    patch 'duplicate'
    patch 'automatic_insert/:destination_id' => 'plannings#automatic_insert'
    patch ':route_id/:destination_id' => 'plannings#update_stop'
    get ':route_id/optimize' => 'plannings#optimize_route'
  end

  resources :routes

  get '/zonings/new/planning/:planning_id' => 'zonings#new'
  resources :zonings do
    get 'edit/planning/:planning_id' => 'zonings#edit'
    get 'planning/:planning_id' => 'zonings#show'
    patch 'duplicate'
  end

  get '/unsupported_browser' => 'index#unsupported_browser'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'index#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end
  
  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
