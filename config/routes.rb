# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)
  concern :active_scaffold_association, ActiveScaffold::Routing::Association.new

  # Defines the root path route ("/")
  # root "articles#index"
  root to: "application#root"

  resources :enrollment_holds do concerns :active_scaffold end

  resources :scholarship_suspensions do concerns :active_scaffold end

  devise_for :users,  controllers: {
    confirmations: "users/confirmations",
    passwords: "users/passwords",
    sessions: "users/sessions",
    unlocks: "users/unlocks",
    invitations: "users/user_invitations",
  }, skip: [:registrations]

  devise_scope :user do
    get "users/sign_up",
      to: "users/registrations#new", as: :new_user_registration
    get "users/profile",
      to: "users/registrations#edit", as: :edit_user_registration
    patch "users/profile",
      to: "users/registrations#update", as: :user_registration
    put "users/profile", to: "users/registrations#update"
    post "users/profile", to: "users/registrations#update"
    post "change_role", to: "user_roles#change_role", as: :change_role
    delete "users/profile", to: "users/registrations#update"
  end


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
      get "summary_pdf"
      get "summary_xls"
    end
    collection do
      get "class_schedule_pdf"
    end
  end

  resources :class_schedules do
    concerns :active_scaffold
    member do
      get "class_schedule_pdf"
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

  resources :research_lines do
    concerns :active_scaffold
    record_select_routes
  end

  resources :professor_research_lines do
    concerns :active_scaffold
    record_select_routes
  end

  resources :course_research_lines do
    concerns :active_scaffold
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
    get "autocomplete", on: :collection
  end

  resources :states do
    concerns :active_scaffold
    get "cities", on: :member
    get "autocomplete", on: :collection
  end

  resources :countries do
    concerns :active_scaffold
    get "states", on: :member
    get "autocomplete", on: :collection
  end

  resources :users do
    concerns :active_scaffold
    record_select_routes
  end

  resources :roles do
    concerns :active_scaffold
  end

  resources :user_roles do
    concerns :active_scaffold
    record_select_routes
  end

  

  resources :scholarship_durations do
    concerns :active_scaffold
    record_select_routes
    collection do
      get "to_pdf"
    end
  end

  resources :scholarships do
    concerns :active_scaffold
    record_select_routes
    collection do
      get "to_pdf"
    end
  end

  resources :advisements do
    concerns :active_scaffold
    record_select_routes
    collection do
      get "to_pdf"
    end
  end

  resources :affiliation do
    concerns :active_scaffold
    record_select_routes
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
      get "to_pdf"
      get "new_users"
      post "create_users"
    end
    member do
      get "academic_transcript_pdf"
      get "academic_transcript/:signature_type.pdf", to: "enrollments#override_signature_transcript_pdf", as: :override_signature_transcript_pdf
      get "grades_report_pdf"
      get "grades_report/:signature_type.pdf", to: "enrollments#override_signature_grades_report_pdf", as: :override_signature_grades_report_pdf
    end
  end

  resources :enrollment_statuses do
    concerns :active_scaffold
  end

  resources :students do
    concerns :active_scaffold
    record_select_routes
  end

  resources :majors do
    concerns :active_scaffold
    record_select_routes
  end

  resources :assertions do
    concerns :active_scaffold
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

  resources :program_levels do
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
      post "execute_now"
      get "simulate"
    end

    collection do
      get "notify"
    end
  end

  resources :queries do
    concerns :active_scaffold
    member do
      get "execute"
    end
  end

  resources :query_params do
    concerns :active_scaffold
  end

  resources :report_configurations do
    concerns :active_scaffold
    collection do
      put "preview"
      post "preview"
      patch "preview"
    end
    member do
      get "logo"
    end
  end


  resources :course_research_areas do
    concerns :active_scaffold
  end

  scope module: "admissions" do
    resources :admission_processes do
      concerns :active_scaffold
      member do
        get :short_pdf
        get :complete_pdf
        get :complete_xls

        get :phase_status
        post :consolidate_phase
        get :rankings
        post :calculate_ranking
      end
      collection do
        get :custom_report
        match :reset_report, via: [:get, :post]
        post :custom_report_generate
      end
      record_select_routes
    end

    resources :admission_applications do
      concerns :active_scaffold
      collection do
        get :configure_all
      end
      member do
        get :configuration
        put :undo_consolidation
        put :cancel
        get :map_student
        post :map_student_form
        post :map_student_form_create_update
      end
      record_select_routes
    end

    resources :form_templates do
      concerns :active_scaffold
      get :populate_field, on: :collection
      member do
        get :populate_field
        get :preview
        post :preview
        patch :preview
      end
      record_select_routes
    end

    resources :consolidation_templates do
      concerns :active_scaffold
    end

    resources :form_fields do
      concerns :active_scaffold
    end

    resources :consolidation_form_fields do
      concerns :active_scaffold
    end

    resources :filled_forms do
      concerns :active_scaffold
    end

    resources :filled_form_fields do
      concerns :active_scaffold
    end

    resources :filled_form_field_scholarities do
      concerns :active_scaffold
    end

    resources :letter_requests do
      concerns :active_scaffold
    end

    resources :admissions, only: [:index, :show] do
      post :find, on: :collection
      post :create, on: :member
      resources :apply, only: [:show, :new, :create, :edit, :update] do
        post :update, on: :member
      end
      resources :letters, only: [:show, :update]
    end

    resources :form_autocompletes, only: [] do
      get :city, on: :collection
      get :state, on: :collection
      get :country, on: :collection
      get :institution, on: :collection
      get :course, on: :collection
      get :form_field, on: :collection
    end

    resources :form_conditions do
      concerns :active_scaffold
    end

    resources :admission_committees do
      concerns :active_scaffold
      get :populate_authorized, on: :collection
      get :populate_professors, on: :collection
      get :populate_coordination, on: :collection
      get :populate_secretary, on: :collection
      member do
        get :populate_authorized
        get :populate_professors
        get :populate_coordination
        get :populate_secretary
      end
      record_select_routes
    end

    resources :admission_committee_members do
      concerns :active_scaffold
    end

    resources :admission_phases do
      concerns :active_scaffold
      record_select_routes
    end

    resources :admission_phase_committees do
      concerns :active_scaffold
    end

    resources :admission_process_phases do
      concerns :active_scaffold
    end

    resources :admission_phase_results do
      concerns :active_scaffold
    end

    resources :admission_phase_evaluations do
      concerns :active_scaffold
    end

    resources :admission_pendencies do
      concerns :active_scaffold
    end

    resources :ranking_machines do
      concerns :active_scaffold
      record_select_routes
    end

    resources :ranking_configs do
      concerns :active_scaffold
      record_select_routes
    end

    resources :ranking_columns do
      concerns :active_scaffold
    end

    resources :ranking_groups do
      concerns :active_scaffold
    end

    resources :ranking_processes do
      concerns :active_scaffold
    end

    resources :admission_process_rankings do
      concerns :active_scaffold
    end

    resources :admission_ranking_results do
      concerns :active_scaffold
    end

    resources :admission_report_configs do
      concerns :active_scaffold
      record_select_routes
    end

    resources :admission_report_groups do
      concerns :active_scaffold
    end

    resources :admission_report_columns do
      concerns :active_scaffold
    end
  end

  get "landing", action: :index, controller: "landing"
  get "files/:medium_hash", action: :download, controller: "files", as: :download
  get "admissions/files/:medium_hash", action: :download, controller: "files"
  get "enrollment/:id", to: "student_enrollment#show", as: :student_enrollment
  get "enrollment/:id/enroll/:year-:semester",
    to: "student_enrollment#enroll", as: :student_enroll
  post "enrollment/:id/enroll/:year-:semester",
    to: "student_enrollment#save_enroll", as: :save_student_enroll

  get "pendencies", to: "pendencies#index", as: :pendencies


  resources :enrollment_requests do
    concerns :active_scaffold
    record_select_routes
    collection do
      get "help"
    end
  end
  resources :class_enrollment_requests do
    concerns :active_scaffold
    collection do
      get "help"
      get "show_effect"
      post "effect"
    end
    member do
      put "set_invalid"
      put "set_requested"
      put "set_valid"
      put "set_effected"
    end
  end
  resources :enrollment_request_comments, concerns: :active_scaffold
  resources :email_templates do
    concerns :active_scaffold
    collection do
      get "builtin"
    end
  end


  resources :email_templates do
    concerns :active_scaffold
    collection do
      get "builtin"
    end
  end

  resources :assertions do
    concerns :active_scaffold
    member do
      get "simulate"
      get "assertion_pdf"
      get "assertion_pdf/:signature_type.pdf", to: "assertions#override_signature_assertion_pdf",  as: :override_signature_assertion_pdf
    end
  end

  resources :reports do
    concerns :active_scaffold
    member do
      get :download
      put :invalidate
    end
    collection do
      get ":identifier.pdf", to: "reports#download_by_identifier", as: :download_by_identifier
    end
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  resources :grants do
    concerns :active_scaffold
  end

  resources :paper_professors do
    concerns :active_scaffold
  end

  resources :paper_students do
    concerns :active_scaffold
  end

  resources :papers do
    concerns :active_scaffold
  end
end
