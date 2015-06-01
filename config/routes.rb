Rails.application.routes.draw do

  use_doorkeeper do
    controllers applications: 'oauth/applications'
  end

  devise_for :users

  resources :jobs do
    post 'retry', on: :member
    post 'inform', on: :member
  end

  resources :tasks do
    post 'inform', on: :member
  end

  namespace :api do
    resources :jobs do
      put 'retry', on: :member
    end
    resources :tasks
  end

  if ENV['WORKER_LIB'] == 'sidekiq' && Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  root 'jobs#index'
end
