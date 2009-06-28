ActionController::Routing::Routes.draw do |map|
  map.resources :slides
  map.namespace :admin do |admin|
    admin.resources :typus_users
    admin.resources :slides
  end

  map.root      :controller => 'slides'
end
