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


  root :to => "application#root"

  resources :enrollment_holds do as_routes end

  resources :scholarship_suspensions do as_routes end

  devise_for :users, :controllers => {:registrations => "users"}

  resources :versions do
    as_routes
  end

  resources :professor_research_areas do
    as_routes
    record_select_routes
  end

  resources :class_enrollments do
    as_routes
    record_select_routes
  end

  resources :allocations do
    as_routes
  end

  resources :course_classes do
    as_routes
    record_select_routes
    member do
      get 'summary_pdf'
    end
    collection do
      get 'class_schedule_pdf'
    end
  end

  resources :course_types do
    as_routes
  end

  resources :courses do
    as_routes
    record_select_routes
  end

  resources :research_areas do
    as_routes
    record_select_routes
  end


  get "credits/show"

  resources :phase_durations do
    as_routes
  end

  resources :deferrals do
    as_routes
  end

  resources :deferral_types do
    as_routes
  end

  resources :accomplishments do
    as_routes
  end

  resources :phases do
    as_routes
  end

  resources :cities do
    as_routes
  end

  resources :states do
    as_routes
    get 'cities', on: :member
  end

  resources :countries do
    as_routes
    get 'states', on: :member
  end

  resources :users do
    as_routes
  end

  resources :roles do
    as_routes
  end

  resources :scholarship_durations do
    as_routes
    record_select_routes
    collection do
      get 'to_pdf'
    end
  end

  resources :scholarships do
    as_routes
    record_select_routes
    collection do
      get 'to_pdf'
    end
  end

  resources :advisements do
    as_routes
    record_select_routes
    collection do
      get 'to_pdf'
    end
  end

  resources :professors do
    as_routes
    record_select_routes
  end

  resources :scholarship_types do
    as_routes
  end

  resources :dismissals do
    as_routes
  end

  resources :dismissal_reasons do
    as_routes
  end

  resources :enrollments do
    as_routes
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
    as_routes
  end

  resources :students do
    as_routes
    record_select_routes
    member do
      get 'photo'
    end
  end

  resources :majors do
    as_routes
    record_select_routes
  end

  resources :levels do
    as_routes
  end

  resources :institutions do
    as_routes
    record_select_routes
  end

  resources :sponsors do
    as_routes
  end

  resources :advisement_authorizations do
    as_routes
  end

  resources :student_majors do
    as_routes
    record_select_routes
  end

  resources :custom_variables do
    as_routes
  end

  resources :thesis_defense_committee_participations do
    as_routes
    record_select_routes
  end

  resources :notification_logs do
    as_routes
  end

  resources :notifications do
    as_routes
    member do
      post 'execute_now'
      get 'simulate'
    end

    collection do
      get 'notify'
    end
  end

  resources :queries do
    as_routes
    member do
      get 'execute'
    end
  end

  resources :query_params do
    as_routes
  end

  resources :notification_params do
    as_routes
  end

  resources :report_configurations do
    as_routes
    collection do
      put 'preview'
      post 'preview'
    end
    member do
      get 'logo'
    end
  end

  resources :course_research_areas do
    as_routes
  end

  resources :student_applications do
    as_routes
  end

  resources :form_templates do
    as_routes
    put :disable, on: :member
  end

  resources :application_processes do
    as_routes
    put :disable, on: :member
    get :application_process_short_pdf, on: :member
    get :application_process_complete_pdf, on: :member
  end

  resources :form_fields do
    as_routes
  end

  get 'apply'  => 'apply#index'
  post 'apply'  => 'apply#create'
  patch 'apply'  => 'apply#update'
  get 'apply/:application_process_id/student_getid'  => 'apply#student_getid', as: :apply_to
  post 'apply/:application_process_id/student_getid'  => 'apply#student_find'
  get 'apply/fill_form/:token' => 'apply#fill_form', as: :fill_form
  get 'apply/student_confirm/:token' => 'apply#student_confirm', as: :student_confirm

  get 'letter_requests/fill/:access_token'  => 'letter_requests#fill', as: :fill_letter
  patch 'letter_requests/:id' => 'letter_requests#update', as: :letter_request
  put 'letter_requests/:id' => 'letter_requests#update'

  post 'apply/student_application' => 'apply#create_student_application', as: :apply_student_application

  #get "/uploads/:id/:basename.:extension", :controller => "form_file_uploads", :action => "download", :conditions => { :method => :get }, as: :form_file_download
  #match "/uploads/:id/:basename.:extension", :controller => "form_file_uploads", :action => "download", via: :get, as: :form_file_download
  match "/form_uploads/:id", :controller => "form_file_uploads", :action => "download", via: :get, as: :form_file_download
  match "/letter_uploads/:id", :controller => "letter_file_uploads", :action => "download", via: :get, as: :letter_file_download

  #get 'form_file_uploads/download/:file_id' => 'form_file_uploads#download', as: :form_file_download
  #get 'letter_file_uploads/download/:file_id' => 'letter_file_uploads#download', as: :letter_file_download
  # resources :letter_requests
  # post 'letter_requests'  => 'letter_requests#create'
  # patch 'letter_requests'  => 'letter_requests#update'


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
