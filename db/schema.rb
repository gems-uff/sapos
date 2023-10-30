# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_10_30_024602) do
  create_table "accomplishments", charset: "utf8mb3", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "phase_id"
    t.date "conclusion_date"
    t.string "obs"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_accomplishments_on_enrollment_id"
    t.index ["phase_id"], name: "index_accomplishments_on_phase_id"
  end

  create_table "active_scaffold_workarounds", charset: "utf8mb3", force: :cascade do |t|
  end

  create_table "admission_applications", charset: "utf8mb3", force: :cascade do |t|
    t.integer "admission_process_id"
    t.string "name"
    t.string "email"
    t.string "token"
    t.integer "filled_form_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_process_id"], name: "index_admission_applications_on_admission_process_id"
    t.index ["filled_form_id"], name: "index_admission_applications_on_filled_form_id"
  end

  create_table "admission_processes", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "simple_url"
    t.integer "semester"
    t.integer "year"
    t.date "start_date"
    t.date "end_date"
    t.integer "form_template_id"
    t.integer "letter_template_id"
    t.integer "min_letters"
    t.integer "max_letters"
    t.boolean "allow_multiple_applications"
    t.boolean "visible", default: true
    t.boolean "require_session", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_template_id"], name: "index_admission_processes_on_form_template_id"
    t.index ["letter_template_id"], name: "index_admission_processes_on_letter_template_id"
  end

  create_table "advisement_authorizations", charset: "utf8mb3", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "level_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["level_id"], name: "index_advisement_authorizations_on_level_id"
    t.index ["professor_id"], name: "index_advisement_authorizations_on_professor_id"
  end

  create_table "advisements", charset: "utf8mb3", force: :cascade do |t|
    t.integer "professor_id", null: false
    t.integer "enrollment_id", null: false
    t.boolean "main_advisor", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_advisements_on_enrollment_id"
    t.index ["professor_id"], name: "index_advisements_on_professor_id"
  end

  create_table "allocations", charset: "utf8mb3", force: :cascade do |t|
    t.string "day"
    t.string "room"
    t.integer "start_time"
    t.integer "end_time"
    t.integer "course_class_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_class_id"], name: "index_allocations_on_course_class_id"
  end

  create_table "carrier_wave_files", charset: "utf8mb3", force: :cascade do |t|
    t.string "medium_hash"
    t.binary "binary"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "reference_counter", default: 0
    t.string "original_filename"
    t.string "content_type"
    t.integer "size"
  end

  create_table "cities", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.integer "state_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "class_enrollment_requests", charset: "utf8mb3", force: :cascade do |t|
    t.integer "enrollment_request_id"
    t.integer "course_class_id"
    t.integer "class_enrollment_id"
    t.string "status", default: "Solicitada"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "action", default: "Adição"
    t.index ["class_enrollment_id"], name: "index_class_enrollment_requests_on_class_enrollment_id"
    t.index ["course_class_id"], name: "index_class_enrollment_requests_on_course_class_id"
    t.index ["enrollment_request_id"], name: "index_class_enrollment_requests_on_enrollment_request_id"
  end

  create_table "class_enrollments", charset: "utf8mb3", force: :cascade do |t|
    t.text "obs"
    t.integer "grade"
    t.string "situation"
    t.integer "course_class_id"
    t.integer "enrollment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "disapproved_by_absence", default: false
    t.boolean "grade_not_count_in_gpr", default: false
    t.string "justification_grade_not_count_in_gpr", default: ""
    t.index ["course_class_id"], name: "index_class_enrollments_on_course_class_id"
    t.index ["enrollment_id"], name: "index_class_enrollments_on_enrollment_id"
  end

  create_table "class_schedules", charset: "utf8mb3", force: :cascade do |t|
    t.integer "year"
    t.integer "semester"
    t.datetime "enrollment_start", precision: nil
    t.datetime "enrollment_end", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "enrollment_adjust", precision: nil
    t.datetime "enrollment_insert", precision: nil
    t.datetime "enrollment_remove", precision: nil
  end

  create_table "countries", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "nationality", default: "-"
  end

  create_table "course_classes", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.integer "course_id"
    t.integer "professor_id"
    t.integer "year"
    t.integer "semester"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "not_schedulable", default: false
    t.string "obs_schedule"
    t.index ["course_id"], name: "index_course_classes_on_course_id"
    t.index ["professor_id"], name: "index_course_classes_on_professor_id"
  end

  create_table "course_research_areas", charset: "utf8mb3", force: :cascade do |t|
    t.integer "course_id"
    t.integer "research_area_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["course_id"], name: "index_course_research_areas_on_course_id"
    t.index ["research_area_id"], name: "index_course_research_areas_on_research_area_id"
  end

  create_table "course_types", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.boolean "has_score"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "schedulable", default: true
    t.boolean "show_class_name", default: true
    t.boolean "allow_multiple_classes", default: false, null: false
    t.boolean "on_demand", default: false, null: false
  end

  create_table "courses", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.text "content"
    t.integer "credits"
    t.integer "course_type_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "workload"
    t.boolean "available", default: true
    t.index ["course_type_id"], name: "index_courses_on_course_type_id"
  end

  create_table "custom_variables", charset: "utf8mb3", force: :cascade do |t|
    t.string "description"
    t.string "variable"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "value"
  end

  create_table "deferral_types", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "duration_semesters", default: 0
    t.integer "phase_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "duration_months", default: 0
    t.integer "duration_days", default: 0
    t.index ["phase_id"], name: "index_deferral_types_on_phase_id"
  end

  create_table "deferrals", charset: "utf8mb3", force: :cascade do |t|
    t.date "approval_date"
    t.string "obs"
    t.integer "enrollment_id"
    t.integer "deferral_type_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["deferral_type_id"], name: "index_deferrals_on_deferral_type_id"
    t.index ["enrollment_id"], name: "index_deferrals_on_enrollment_id"
  end

  create_table "dismissal_reasons", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "show_advisor_name", default: false
    t.string "thesis_judgement"
  end

  create_table "dismissals", charset: "utf8mb3", force: :cascade do |t|
    t.date "date"
    t.integer "enrollment_id"
    t.integer "dismissal_reason_id"
    t.text "obs"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["dismissal_reason_id"], name: "index_dismissals_on_dismissal_reason_id"
    t.index ["enrollment_id"], name: "index_dismissals_on_enrollment_id"
  end

  create_table "email_templates", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "to"
    t.string "subject"
    t.text "body"
    t.boolean "enabled", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "enrollment_holds", charset: "utf8mb3", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "year"
    t.integer "semester"
    t.integer "number_of_semesters", default: 1
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true
    t.index ["enrollment_id"], name: "index_enrollment_holds_on_enrollment_id"
  end

  create_table "enrollment_request_comments", charset: "utf8mb3", force: :cascade do |t|
    t.text "message"
    t.integer "enrollment_request_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_request_id"], name: "index_enrollment_request_comments_on_enrollment_request_id"
    t.index ["user_id"], name: "index_enrollment_request_comments_on_user_id"
  end

  create_table "enrollment_requests", charset: "utf8mb3", force: :cascade do |t|
    t.integer "year"
    t.integer "semester"
    t.integer "enrollment_id"
    t.datetime "last_student_change_at", precision: nil
    t.datetime "last_staff_change_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "student_view_at", precision: nil
    t.index ["enrollment_id"], name: "index_enrollment_requests_on_enrollment_id"
  end

  create_table "enrollment_statuses", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "user"
  end

  create_table "enrollments", charset: "utf8mb3", force: :cascade do |t|
    t.string "enrollment_number"
    t.integer "student_id"
    t.integer "level_id"
    t.integer "enrollment_status_id"
    t.date "admission_date"
    t.text "obs"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "thesis_title"
    t.date "thesis_defense_date"
    t.integer "research_area_id"
    t.index ["enrollment_status_id"], name: "index_enrollments_on_enrollment_status_id"
    t.index ["level_id"], name: "index_enrollments_on_level_id"
    t.index ["research_area_id"], name: "index_enrollments_on_research_area_id"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "filled_form_field_scholarities", charset: "utf8mb3", force: :cascade do |t|
    t.integer "filled_form_field_id"
    t.string "level"
    t.string "status"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "start_date"
    t.string "institution"
    t.string "course"
    t.string "grade"
    t.string "location"
    t.index ["filled_form_field_id"], name: "index_filled_form_field_scholarities_on_filled_form_field_id"
  end

  create_table "filled_form_fields", charset: "utf8mb3", force: :cascade do |t|
    t.integer "filled_form_id"
    t.integer "form_field_id"
    t.text "value"
    t.string "list"
    t.string "file"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["filled_form_id"], name: "index_filled_form_fields_on_filled_form_id"
    t.index ["form_field_id"], name: "index_filled_form_fields_on_form_field_id"
  end

  create_table "filled_forms", charset: "utf8mb3", force: :cascade do |t|
    t.integer "form_template_id"
    t.boolean "is_filled"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_template_id"], name: "index_filled_forms_on_form_template_id"
  end

  create_table "form_fields", charset: "utf8mb3", force: :cascade do |t|
    t.integer "form_template_id"
    t.integer "order"
    t.string "name"
    t.string "description"
    t.string "field_type"
    t.string "configuration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sync"
    t.index ["form_template_id"], name: "index_form_fields_on_form_template_id"
  end

  create_table "form_templates", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "template_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "institutions", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "code"
  end

  create_table "letter_requests", charset: "utf8mb3", force: :cascade do |t|
    t.integer "admission_application_id"
    t.string "name"
    t.string "email"
    t.string "telephone"
    t.string "access_token"
    t.string "sent_email"
    t.integer "filled_form_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_application_id"], name: "index_letter_requests_on_admission_application_id"
    t.index ["filled_form_id"], name: "index_letter_requests_on_filled_form_id"
  end

  create_table "levels", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "course_name"
    t.integer "default_duration", default: 0
    t.boolean "show_advisements_points_in_list"
    t.string "short_name_showed_in_list_header"
  end

  create_table "majors", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.integer "level_id"
    t.integer "institution_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["institution_id"], name: "index_majors_on_institution_id"
    t.index ["level_id"], name: "index_majors_on_level_id"
  end

  create_table "notification_logs", charset: "utf8mb3", force: :cascade do |t|
    t.integer "notification_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "to"
    t.string "subject"
    t.text "body"
    t.string "attachments_file_names"
    t.index ["notification_id"], name: "index_notification_logs_on_notification_id"
  end

  create_table "notifications", charset: "utf8mb3", force: :cascade do |t|
    t.string "title"
    t.string "to_template"
    t.string "subject_template"
    t.text "body_template"
    t.string "notification_offset"
    t.string "query_offset"
    t.string "frequency"
    t.datetime "next_execution", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "individual", default: true
    t.integer "query_id", null: false
    t.boolean "has_grades_report_pdf_attachment", default: false
    t.index ["query_id"], name: "index_notifications_on_query_id"
  end

  create_table "phase_completions", charset: "utf8mb3", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "phase_id"
    t.datetime "due_date", precision: nil
    t.datetime "completion_date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_phase_completions_on_enrollment_id"
    t.index ["phase_id"], name: "index_phase_completions_on_phase_id"
  end

  create_table "phase_durations", charset: "utf8mb3", force: :cascade do |t|
    t.integer "phase_id"
    t.integer "level_id"
    t.integer "deadline_semesters", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "deadline_months", default: 0
    t.integer "deadline_days", default: 0
    t.index ["level_id"], name: "index_phase_durations_on_level_id"
    t.index ["phase_id"], name: "index_phase_durations_on_phase_id"
  end

  create_table "phases", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_language", default: false
    t.boolean "extend_on_hold", default: false
    t.boolean "active", default: true
  end

  create_table "professor_research_areas", charset: "utf8mb3", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "research_area_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["professor_id"], name: "index_professor_research_areas_on_professor_id"
    t.index ["research_area_id"], name: "index_professor_research_areas_on_research_area_id"
  end

  create_table "professors", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "cpf"
    t.date "birthdate"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "sex"
    t.string "civil_status"
    t.string "identity_number"
    t.string "identity_issuing_body"
    t.string "identity_expedition_date"
    t.string "neighborhood"
    t.string "address"
    t.integer "city_id"
    t.string "zip_code"
    t.string "telephone1"
    t.string "telephone2"
    t.string "siape"
    t.string "enrollment_number"
    t.string "identity_issuing_place"
    t.integer "institution_id"
    t.string "email"
    t.date "academic_title_date"
    t.integer "academic_title_country_id"
    t.integer "academic_title_institution_id"
    t.integer "academic_title_level_id"
    t.text "obs"
    t.integer "user_id"
    t.index ["academic_title_country_id"], name: "index_professors_on_academic_title_country_id"
    t.index ["academic_title_institution_id"], name: "index_professors_on_academic_title_institution_id"
    t.index ["academic_title_level_id"], name: "index_professors_on_academic_title_level_id"
    t.index ["city_id"], name: "index_professors_on_city_id"
    t.index ["email"], name: "index_professors_on_email"
    t.index ["institution_id"], name: "index_professors_on_institution_id"
    t.index ["user_id"], name: "index_professors_on_user_id"
  end

  create_table "queries", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.text "sql"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "description"
  end

  create_table "query_params", charset: "utf8mb3", force: :cascade do |t|
    t.integer "query_id"
    t.string "name"
    t.string "default_value"
    t.string "value_type"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["query_id"], name: "index_query_params_on_query_id"
  end

  create_table "report_configurations", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.boolean "use_at_report"
    t.boolean "use_at_transcript"
    t.boolean "use_at_grades_report"
    t.boolean "use_at_schedule"
    t.text "text"
    t.string "image"
    t.boolean "signature_footer"
    t.integer "order", default: 2
    t.decimal "scale", precision: 10, scale: 8
    t.integer "x"
    t.integer "y"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "research_areas", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "roles", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "description", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "scholarship_durations", charset: "utf8mb3", force: :cascade do |t|
    t.integer "scholarship_id", null: false
    t.integer "enrollment_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "obs"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.date "cancel_date"
    t.index ["enrollment_id"], name: "index_scholarship_durations_on_enrollment_id"
    t.index ["scholarship_id"], name: "index_scholarship_durations_on_scholarship_id"
  end

  create_table "scholarship_suspensions", charset: "utf8mb3", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true
    t.integer "scholarship_duration_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["scholarship_duration_id"], name: "index_scholarship_suspensions_on_scholarship_duration_id"
  end

  create_table "scholarship_types", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "scholarships", charset: "utf8mb3", force: :cascade do |t|
    t.string "scholarship_number"
    t.integer "level_id"
    t.integer "sponsor_id"
    t.integer "scholarship_type_id"
    t.date "start_date"
    t.date "end_date"
    t.text "obs"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "professor_id"
    t.index ["level_id"], name: "index_scholarships_on_level_id"
    t.index ["professor_id"], name: "index_scholarships_on_professor_id"
    t.index ["scholarship_type_id"], name: "index_scholarships_on_scholarship_type_id"
    t.index ["sponsor_id"], name: "index_scholarships_on_sponsor_id"
  end

  create_table "sessions", charset: "utf8mb3", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "sponsors", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "states", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.integer "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["country_id"], name: "index_states_on_country_id"
  end

  create_table "student_majors", charset: "utf8mb3", force: :cascade do |t|
    t.integer "major_id", null: false
    t.integer "student_id", null: false
    t.index ["major_id"], name: "index_student_majors_on_major_id"
    t.index ["student_id"], name: "index_student_majors_on_student_id"
  end

  create_table "students", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.string "cpf"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "obs"
    t.date "birthdate"
    t.string "sex"
    t.string "civil_status"
    t.string "father_name"
    t.string "mother_name"
    t.string "identity_number"
    t.string "identity_issuing_body"
    t.date "identity_expedition_date"
    t.string "employer"
    t.string "job_position"
    t.integer "birth_state_id"
    t.integer "city_id"
    t.string "neighborhood"
    t.string "zip_code"
    t.string "address"
    t.string "telephone1"
    t.string "telephone2"
    t.string "email"
    t.integer "birth_city_id"
    t.string "identity_issuing_place"
    t.string "photo"
    t.integer "birth_country_id"
    t.bigint "user_id"
    t.index ["birth_city_id"], name: "index_students_on_birth_city_id"
    t.index ["birth_country_id"], name: "index_students_on_birth_country_id"
    t.index ["birth_state_id"], name: "index_students_on_state_id"
    t.index ["city_id"], name: "index_students_on_city_id"
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "thesis_defense_committee_participations", charset: "utf8mb3", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "enrollment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_thesis_defense_committee_participations_on_enrollment_id"
    t.index ["professor_id"], name: "index_thesis_defense_committee_participations_on_professor_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.integer "role_id", default: 1, null: false
    t.string "unconfirmed_email"
    t.string "invitation_token"
    t.datetime "invitation_created_at", precision: nil
    t.datetime "invitation_sent_at", precision: nil
    t.datetime "invitation_accepted_at", precision: nil
    t.integer "invitation_limit"
    t.string "invited_by_type"
    t.integer "invited_by_id"
    t.integer "invitations_count", default: 0
    t.index ["email"], name: "index_users_on_email"
    t.index ["invitation_token"], name: "index_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_users_on_invited_by_id"
    t.index ["invited_by_type", "invited_by_id"], name: "index_users_on_invited_by_type_and_invited_by_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "versions", charset: "utf8mb3", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", size: :medium
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
