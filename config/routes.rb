# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

Sapos::Application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):

  concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
  concern :active_scaffold_association, ActiveScaffold::Routing::Association.new

  root :to => "application#root"

  resources :enrollment_holds do concerns :active_scaffold end

  resources :scholarship_suspensions do concerns :active_scaffold end

  devise_for :users, :controllers => {:registrations => "users"}

  resources :versions do
    concerns :active_scaffold
  end

  resources :professor_research_areas do
    concerns :active_scaffold
    record_select_routes
  end

  resources :class_enrollments do
    concerns :active_scaffold
    record_select_routes
  end

  resources :allocations do
    concerns :active_scaffold
  end

  resources :course_classes do
    concerns :active_scaffold
    record_select_routes
    member do
      get 'summary_pdf'
    end
    collection do
      get 'class_schedule_pdf'
    end
  end

  resources :course_types do
    concerns :active_scaffold
  end

  resources :courses do
    concerns :active_scaffold
    record_select_routes
  end

  resources :research_areas do
    concerns :active_scaffold
    record_select_routes
  end


  get "credits/show"

  resources :phase_durations do
    concerns :active_scaffold
  end

  resources :deferrals do
    concerns :active_scaffold
  end

  resources :deferral_types do
    concerns :active_scaffold
  end

  resources :accomplishments do
    concerns :active_scaffold
  end

  resources :phases do
    concerns :active_scaffold
  end

  resources :cities do
    concerns :active_scaffold
  end

  resources :states do
    concerns :active_scaffold
    get 'cities', on: :member
  end

  resources :countries do
    concerns :active_scaffold
    get 'states', on: :member
  end

  resources :users do
    concerns :active_scaffold
    collection do
      get 'create_students'
      post 'apply_create'
    end
  end

  resources :roles do
    concerns :active_scaffold
  end

  resources :scholarship_durations do
    concerns :active_scaffold
    record_select_routes
    collection do
      get 'to_pdf'
    end
  end

  resources :scholarships do
    concerns :active_scaffold
    record_select_routes
    collection do
      get 'to_pdf'
    end
  end

  resources :advisements do
    concerns :active_scaffold
    record_select_routes
    collection do
      get 'to_pdf'
    end
  end

  resources :professors do
    concerns :active_scaffold
    record_select_routes
  end

  resources :scholarship_types do
    concerns :active_scaffold
  end

  resources :dismissals do
    concerns :active_scaffold
  end

  resources :dismissal_reasons do
    concerns :active_scaffold
  end

  resources :enrollments do
    concerns :active_scaffold
    record_select_routes
    collection do
      get 'to_pdf'
    end
    member do
      get 'academic_transcript_pdf'
      get 'grades_report_pdf'
    end
  end

  resources :enrollment_statuses do
    concerns :active_scaffold
  end

  resources :students do
    concerns :active_scaffold
    record_select_routes
    member do
      get 'photo'
    end
  end

  resources :majors do
    concerns :active_scaffold
    record_select_routes
  end

  resources :levels do
    concerns :active_scaffold
  end

  resources :institutions do
    concerns :active_scaffold
    record_select_routes
  end

  resources :sponsors do
    concerns :active_scaffold
  end

  resources :advisement_authorizations do
    concerns :active_scaffold
  end

  resources :student_majors do
    concerns :active_scaffold
    record_select_routes
  end

  resources :custom_variables do
    concerns :active_scaffold
  end

  resources :thesis_defense_committee_participations do
    concerns :active_scaffold
    record_select_routes
  end

  resources :notification_logs do
    concerns :active_scaffold
  end

  resources :notifications do
    concerns :active_scaffold
    member do
      post 'execute_now'
      get 'simulate'
    end

    collection do
      get 'notify'
    end
  end

  resources :queries do
    concerns :active_scaffold
    member do
      get 'execute'
    end
  end

  resources :query_params do
    concerns :active_scaffold
  end

  resources :notification_params do
    concerns :active_scaffold
  end

  resources :report_configurations do
    concerns :active_scaffold
    collection do
      put 'preview'
      post 'preview'
      patch 'preview'
    end
    member do
      get 'logo'
    end
  end


  resources :course_research_areas do
    concerns :active_scaffold
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
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
