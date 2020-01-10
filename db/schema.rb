# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200110161221) do

  create_table "accomplishments", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "phase_id"
    t.date "conclusion_date"
    t.string "obs", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id"], name: "index_accomplishments_on_enrollment_id"
    t.index ["phase_id"], name: "index_accomplishments_on_phase_id"
  end

  create_table "advisement_authorizations", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "level_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id"], name: "index_advisement_authorizations_on_level_id"
    t.index ["professor_id"], name: "index_advisement_authorizations_on_professor_id"
  end

  create_table "advisements", force: :cascade do |t|
    t.integer "professor_id", null: false
    t.integer "enrollment_id", null: false
    t.boolean "main_advisor", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id"], name: "index_advisements_on_enrollment_id"
    t.index ["professor_id"], name: "index_advisements_on_professor_id"
  end

  create_table "allocations", force: :cascade do |t|
    t.string "day", limit: 255
    t.string "room", limit: 255
    t.integer "start_time"
    t.integer "end_time"
    t.integer "course_class_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_class_id"], name: "index_allocations_on_course_class_id"
  end

  create_table "carrier_wave_files", force: :cascade do |t|
    t.string "medium_hash", limit: 255
    t.binary "binary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "reference_counter", default: 0
  end

  create_table "cities", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "state_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "class_enrollments", force: :cascade do |t|
    t.text "obs"
    t.integer "grade"
    t.string "situation", limit: 255
    t.integer "course_class_id"
    t.integer "enrollment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "disapproved_by_absence", default: false
    t.index ["course_class_id"], name: "index_class_enrollments_on_course_class_id"
    t.index ["enrollment_id"], name: "index_class_enrollments_on_enrollment_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "nationality", default: "-"
  end

  create_table "course_classes", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "course_id"
    t.integer "professor_id"
    t.integer "year"
    t.integer "semester"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_classes_on_course_id"
    t.index ["professor_id"], name: "index_course_classes_on_professor_id"
  end

  create_table "course_research_areas", force: :cascade do |t|
    t.integer "course_id"
    t.integer "research_area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "has_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "schedulable", default: true
    t.boolean "show_class_name", default: true
    t.boolean "allow_multiple_classes", default: false, null: false
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.text "content"
    t.integer "credits"
    t.integer "course_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "workload"
    t.boolean "available", default: true
    t.index ["course_type_id"], name: "index_courses_on_course_type_id"
  end

  create_table "custom_variables", force: :cascade do |t|
    t.string "description", limit: 255
    t.string "variable", limit: 255
    t.text "value", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "deferral_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.integer "duration_semesters", default: 0
    t.integer "phase_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration_months", default: 0
    t.integer "duration_days", default: 0
    t.index ["phase_id"], name: "index_deferral_types_on_phase_id"
  end

  create_table "deferrals", force: :cascade do |t|
    t.date "approval_date"
    t.string "obs", limit: 255
    t.integer "enrollment_id"
    t.integer "deferral_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deferral_type_id"], name: "index_deferrals_on_deferral_type_id"
    t.index ["enrollment_id"], name: "index_deferrals_on_enrollment_id"
  end

  create_table "dismissal_reasons", force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "show_advisor_name", default: false
    t.string "thesis_judgement", limit: 255
  end

  create_table "dismissals", force: :cascade do |t|
    t.date "date"
    t.integer "enrollment_id"
    t.integer "dismissal_reason_id"
    t.text "obs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dismissal_reason_id"], name: "index_dismissals_on_dismissal_reason_id"
    t.index ["enrollment_id"], name: "index_dismissals_on_enrollment_id"
  end

  create_table "enrollment_holds", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "year"
    t.integer "semester"
    t.integer "number_of_semesters", default: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true
    t.index ["enrollment_id"], name: "index_enrollment_holds_on_enrollment_id"
  end

  create_table "enrollment_statuses", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "enrollments", force: :cascade do |t|
    t.string "enrollment_number", limit: 255
    t.integer "student_id"
    t.integer "level_id"
    t.integer "enrollment_status_id"
    t.date "admission_date"
    t.text "obs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "thesis_title", limit: 255
    t.date "thesis_defense_date"
    t.integer "research_area_id"
    t.index ["enrollment_status_id"], name: "index_enrollments_on_enrollment_status_id"
    t.index ["level_id"], name: "index_enrollments_on_level_id"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "institutions", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code", limit: 255
  end

  create_table "levels", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "course_name", limit: 255
    t.integer "default_duration", default: 0
  end

  create_table "majors", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "level_id"
    t.integer "institution_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_majors_on_institution_id"
    t.index ["level_id"], name: "index_majors_on_level_id"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.integer "notification_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "to", limit: 255
    t.string "subject", limit: 255
    t.text "body"
    t.index ["notification_id"], name: "index_notification_logs_on_notification_id"
  end

  create_table "notification_params", force: :cascade do |t|
    t.integer "notification_id"
    t.integer "query_param_id"
    t.string "value", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false, null: false
    t.index ["notification_id"], name: "index_notification_params_on_notification_id"
    t.index ["query_param_id"], name: "index_notification_params_on_query_param_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "title", limit: 255
    t.string "to_template", limit: 255
    t.string "subject_template", limit: 255
    t.text "body_template"
    t.string "notification_offset", limit: 255
    t.string "query_offset", limit: 255
    t.string "frequency", limit: 255
    t.datetime "next_execution"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "individual", default: true
    t.integer "query_id", null: false
  end

  create_table "phase_completions", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "phase_id"
    t.datetime "due_date"
    t.datetime "completion_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "phase_durations", force: :cascade do |t|
    t.integer "phase_id"
    t.integer "level_id"
    t.integer "deadline_semesters", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "deadline_months", default: 0
    t.integer "deadline_days", default: 0
    t.index ["level_id"], name: "index_phase_durations_on_level_id"
    t.index ["phase_id"], name: "index_phase_durations_on_phase_id"
  end

  create_table "phases", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_language", default: false
    t.boolean "extend_on_hold", default: false
  end

  create_table "professor_research_areas", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "research_area_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professor_id"], name: "index_professor_research_areas_on_professor_id"
    t.index ["research_area_id"], name: "index_professor_research_areas_on_research_area_id"
  end

  create_table "professors", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "cpf", limit: 255
    t.date "birthdate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sex", limit: 255
    t.string "civil_status", limit: 255
    t.string "identity_number", limit: 255
    t.string "identity_issuing_body", limit: 255
    t.string "identity_expedition_date", limit: 255
    t.string "neighborhood", limit: 255
    t.string "address", limit: 255
    t.integer "city_id"
    t.string "zip_code", limit: 255
    t.string "telephone1", limit: 255
    t.string "telephone2", limit: 255
    t.string "siape", limit: 255
    t.string "enrollment_number", limit: 255
    t.string "identity_issuing_place", limit: 255
    t.integer "institution_id"
    t.string "email", limit: 255
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

  create_table "queries", force: :cascade do |t|
    t.string "name", limit: 255
    t.text "sql"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description", limit: 255
  end

  create_table "query_params", force: :cascade do |t|
    t.integer "query_id"
    t.string "name", limit: 255
    t.string "default_value", limit: 255
    t.string "value_type", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["query_id"], name: "index_query_params_on_query_id"
  end

  create_table "report_configurations", force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "use_at_report"
    t.boolean "use_at_transcript"
    t.boolean "use_at_grades_report"
    t.boolean "use_at_schedule"
    t.text "text"
    t.string "image", limit: 255
    t.boolean "signature_footer"
    t.integer "order", default: 2
    t.decimal "scale", precision: 10, scale: 8
    t.integer "x"
    t.integer "y"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "research_areas", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "description", limit: 255, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scholarship_durations", force: :cascade do |t|
    t.integer "scholarship_id", null: false
    t.integer "enrollment_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "obs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "cancel_date"
    t.index ["enrollment_id"], name: "index_scholarship_durations_on_enrollment_id"
    t.index ["scholarship_id"], name: "index_scholarship_durations_on_scholarship_id"
  end

  create_table "scholarship_suspensions", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true
    t.integer "scholarship_duration_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["scholarship_duration_id"], name: "index_scholarship_suspensions_on_scholarship_duration_id"
  end

  create_table "scholarship_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "scholarships", force: :cascade do |t|
    t.string "scholarship_number", limit: 255
    t.integer "level_id"
    t.integer "sponsor_id"
    t.integer "scholarship_type_id"
    t.date "start_date"
    t.date "end_date"
    t.text "obs"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "professor_id"
    t.index ["level_id"], name: "index_scholarships_on_level_id"
    t.index ["professor_id"], name: "index_scholarships_on_professor_id"
    t.index ["scholarship_type_id"], name: "index_scholarships_on_scholarship_type_id"
    t.index ["sponsor_id"], name: "index_scholarships_on_sponsor_id"
  end

  create_table "sponsors", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "states", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.integer "country_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_states_on_country_id"
  end

  create_table "student_majors", force: :cascade do |t|
    t.integer "major_id", null: false
    t.integer "student_id", null: false
    t.index ["major_id"], name: "index_student_majors_on_major_id"
    t.index ["student_id"], name: "index_student_majors_on_student_id"
  end

  create_table "students", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "cpf", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "obs"
    t.date "birthdate"
    t.string "sex", limit: 255
    t.string "civil_status", limit: 255
    t.string "father_name", limit: 255
    t.string "mother_name", limit: 255
    t.string "identity_number", limit: 255
    t.string "identity_issuing_body", limit: 255
    t.date "identity_expedition_date"
    t.string "employer", limit: 255
    t.string "job_position", limit: 255
    t.integer "birth_state_id"
    t.integer "city_id"
    t.string "neighborhood", limit: 255
    t.string "zip_code", limit: 255
    t.string "address", limit: 255
    t.string "telephone1", limit: 255
    t.string "telephone2", limit: 255
    t.string "email", limit: 255
    t.integer "birth_city_id"
    t.string "identity_issuing_place", limit: 255
    t.string "photo", limit: 255
    t.integer "birth_country_id"
    t.index ["birth_city_id"], name: "index_students_on_birth_city_id"
    t.index ["birth_country_id"], name: "index_students_on_birth_country_id"
    t.index ["birth_state_id"], name: "index_students_on_state_id"
    t.index ["city_id"], name: "index_students_on_city_id"
  end

  create_table "thesis_defense_committee_participations", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "enrollment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id"], name: "index_thesis_defense_committee_participations_on_enrollment_id"
    t.index ["professor_id"], name: "index_thesis_defense_committee_participations_on_professor_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "hashed_password", limit: 255
    t.string "salt", limit: 255
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer "failed_attempts", default: 0
    t.string "unlock_token", limit: 255
    t.datetime "locked_at"
    t.integer "role_id", default: 1, null: false
    t.string "unconfirmed_email"
    t.index ["email"], name: "index_users_on_email"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", limit: 255, null: false
    t.integer "item_id", null: false
    t.string "event", limit: 255, null: false
    t.string "whodunnit", limit: 255
    t.text "object", limit: 16777215
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

end
