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

ActiveRecord::Schema[7.0].define(version: 2024_12_20_150416) do
  create_table "accomplishments", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "phase_id"
    t.date "conclusion_date"
    t.string "obs", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_accomplishments_on_enrollment_id"
    t.index ["phase_id"], name: "index_accomplishments_on_phase_id"
  end

  create_table "active_scaffold_workarounds", force: :cascade do |t|
  end

  create_table "admission_applications", force: :cascade do |t|
    t.integer "admission_process_id"
    t.string "name"
    t.string "email"
    t.string "token"
    t.integer "filled_form_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admission_phase_id"
    t.string "status"
    t.text "status_message"
    t.datetime "submission_time"
    t.integer "student_id"
    t.integer "enrollment_id"
    t.index ["admission_phase_id"], name: "index_admission_applications_on_admission_phase_id"
    t.index ["admission_process_id"], name: "index_admission_applications_on_admission_process_id"
    t.index ["enrollment_id"], name: "index_admission_applications_on_enrollment_id"
    t.index ["filled_form_id"], name: "index_admission_applications_on_filled_form_id"
    t.index ["student_id"], name: "index_admission_applications_on_student_id"
    t.index ["token"], name: "index_admission_applications_on_token"
  end

  create_table "admission_committee_members", force: :cascade do |t|
    t.integer "admission_committee_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_committee_id"], name: "index_admission_committee_members_on_admission_committee_id"
    t.index ["user_id"], name: "index_admission_committee_members_on_user_id"
  end

  create_table "admission_committees", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "form_condition_id"
    t.index ["form_condition_id"], name: "index_admission_committees_on_form_condition_id"
  end

  create_table "admission_pendencies", force: :cascade do |t|
    t.integer "admission_application_id"
    t.integer "admission_phase_id"
    t.integer "user_id"
    t.string "mode"
    t.string "status", default: "Pendente"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_application_id", "admission_phase_id", "status"], name: "admission_pendencies_candidate_phase_status"
    t.index ["admission_application_id", "user_id"], name: "admission_pendencies_candidate_user"
    t.index ["admission_application_id"], name: "index_admission_pendencies_on_admission_application_id"
    t.index ["admission_phase_id"], name: "index_admission_pendencies_on_admission_phase_id"
    t.index ["user_id"], name: "index_admission_pendencies_on_user_id"
  end

  create_table "admission_phase_committees", force: :cascade do |t|
    t.integer "admission_committee_id"
    t.integer "admission_phase_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_committee_id"], name: "index_admission_phase_committees_on_admission_committee_id"
    t.index ["admission_phase_id"], name: "index_admission_phase_committees_on_admission_phase_id"
  end

  create_table "admission_phase_evaluations", force: :cascade do |t|
    t.integer "admission_phase_id"
    t.integer "user_id"
    t.integer "admission_application_id"
    t.integer "filled_form_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_application_id"], name: "index_admission_phase_evaluations_on_admission_application_id"
    t.index ["admission_phase_id"], name: "index_admission_phase_evaluations_on_admission_phase_id"
    t.index ["filled_form_id"], name: "index_admission_phase_evaluations_on_filled_form_id"
    t.index ["user_id"], name: "index_admission_phase_evaluations_on_user_id"
  end

  create_table "admission_phase_results", force: :cascade do |t|
    t.integer "admission_phase_id"
    t.integer "admission_application_id"
    t.integer "filled_form_id"
    t.string "mode"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_application_id"], name: "index_admission_phase_results_on_admission_application_id"
    t.index ["admission_phase_id"], name: "index_admission_phase_results_on_admission_phase_id"
    t.index ["filled_form_id"], name: "index_admission_phase_results_on_filled_form_id"
  end

  create_table "admission_phases", force: :cascade do |t|
    t.string "name"
    t.integer "member_form_id"
    t.integer "shared_form_id"
    t.integer "consolidation_form_id"
    t.boolean "can_edit_candidate", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "approval_condition_id"
    t.integer "keep_in_phase_condition_id"
    t.integer "candidate_form_id"
    t.boolean "candidate_can_edit", default: false, null: false
    t.boolean "candidate_can_see_member", default: false, null: false
    t.boolean "candidate_can_see_shared", default: false, null: false
    t.boolean "candidate_can_see_consolidation", default: false, null: false
    t.boolean "committee_can_see_other_individual", default: false, null: false
    t.index ["approval_condition_id"], name: "index_admission_phases_on_approval_condition_id"
    t.index ["candidate_form_id"], name: "index_admission_phases_on_candidate_form_id"
    t.index ["consolidation_form_id"], name: "index_admission_phases_on_consolidation_form_id"
    t.index ["keep_in_phase_condition_id"], name: "index_admission_phases_on_keep_in_phase_condition_id"
    t.index ["member_form_id"], name: "index_admission_phases_on_member_form_id"
    t.index ["shared_form_id"], name: "index_admission_phases_on_shared_form_id"
  end

  create_table "admission_process_phases", force: :cascade do |t|
    t.integer "admission_process_id"
    t.integer "admission_phase_id"
    t.date "start_date"
    t.date "end_date"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "partial_consolidation", default: true, null: false
    t.index ["admission_phase_id"], name: "index_admission_process_phases_on_admission_phase_id"
    t.index ["admission_process_id"], name: "index_admission_process_phases_on_admission_process_id"
  end

  create_table "admission_process_rankings", force: :cascade do |t|
    t.integer "ranking_config_id"
    t.integer "admission_process_id"
    t.integer "admission_phase_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order"
    t.index ["admission_phase_id"], name: "index_admission_process_rankings_on_admission_phase_id"
    t.index ["admission_process_id"], name: "index_admission_process_rankings_on_admission_process_id"
    t.index ["ranking_config_id"], name: "index_admission_process_rankings_on_ranking_config_id"
  end

  create_table "admission_processes", force: :cascade do |t|
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
    t.boolean "allow_multiple_applications", default: false, null: false
    t.boolean "visible", default: true, null: false
    t.boolean "require_session", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "edit_date"
    t.boolean "staff_can_edit", default: false, null: false
    t.boolean "staff_can_undo", default: false, null: false
    t.integer "level_id"
    t.integer "enrollment_status_id"
    t.string "enrollment_number_field"
    t.date "admission_date"
    t.index ["enrollment_status_id"], name: "index_admission_processes_on_enrollment_status_id"
    t.index ["form_template_id"], name: "index_admission_processes_on_form_template_id"
    t.index ["letter_template_id"], name: "index_admission_processes_on_letter_template_id"
    t.index ["level_id"], name: "index_admission_processes_on_level_id"
    t.index ["simple_url"], name: "index_admission_processes_on_simple_url"
  end

  create_table "admission_ranking_results", force: :cascade do |t|
    t.integer "ranking_config_id"
    t.integer "admission_application_id"
    t.integer "filled_form_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_application_id"], name: "index_admission_ranking_results_on_admission_application_id"
    t.index ["filled_form_id"], name: "index_admission_ranking_results_on_filled_form_id"
    t.index ["ranking_config_id"], name: "index_admission_ranking_results_on_ranking_config_id"
  end

  create_table "admission_report_columns", force: :cascade do |t|
    t.integer "admission_report_group_id"
    t.integer "order"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admission_report_group_id"], name: "index_admission_report_columns_on_admission_report_group_id"
  end

  create_table "admission_report_configs", force: :cascade do |t|
    t.string "name"
    t.integer "form_template_id"
    t.integer "form_condition_id"
    t.string "group_column_tabular"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "hide_empty_sections", default: false, null: false
    t.boolean "show_partial_candidates", default: false, null: false
    t.index ["form_condition_id"], name: "index_admission_report_configs_on_form_condition_id"
    t.index ["form_template_id"], name: "index_admission_report_configs_on_form_template_id"
  end

  create_table "admission_report_groups", force: :cascade do |t|
    t.integer "admission_report_config_id"
    t.integer "order"
    t.string "mode"
    t.string "operation"
    t.string "committee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "in_simple", default: false, null: false
    t.string "pdf_format"
    t.index ["admission_report_config_id"], name: "index_admission_report_groups_on_admission_report_config_id"
  end

  create_table "advisement_authorizations", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "level_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["level_id"], name: "index_advisement_authorizations_on_level_id"
    t.index ["professor_id"], name: "index_advisement_authorizations_on_professor_id"
  end

  create_table "advisements", force: :cascade do |t|
    t.integer "professor_id", null: false
    t.integer "enrollment_id", null: false
    t.boolean "main_advisor", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_advisements_on_enrollment_id"
    t.index ["professor_id"], name: "index_advisements_on_professor_id"
  end

  create_table "allocations", force: :cascade do |t|
    t.string "day", limit: 255
    t.string "room", limit: 255
    t.integer "start_time"
    t.integer "end_time"
    t.integer "course_class_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_class_id"], name: "index_allocations_on_course_class_id"
  end

  create_table "carrier_wave_files", force: :cascade do |t|
    t.string "medium_hash", limit: 255
    t.binary "binary"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "reference_counter", default: 0
    t.string "original_filename"
    t.string "content_type"
    t.integer "size"
    t.index ["medium_hash"], name: "index_carrier_wave_files_on_medium_hash"
  end

  create_table "assertions", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "query_id", null: false
    t.string "assertion_template"
    t.index ["query_id"], name: "index_assertions_on_query_id"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "state_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "class_enrollment_requests", force: :cascade do |t|
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

  create_table "class_enrollments", force: :cascade do |t|
    t.text "obs"
    t.integer "grade"
    t.string "situation", limit: 255
    t.integer "course_class_id"
    t.integer "enrollment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "disapproved_by_absence", default: false, null: false
    t.boolean "grade_not_count_in_gpr", default: false, null: false
    t.string "justification_grade_not_count_in_gpr", default: ""
    t.index ["course_class_id"], name: "index_class_enrollments_on_course_class_id"
    t.index ["enrollment_id"], name: "index_class_enrollments_on_enrollment_id"
  end

  create_table "class_schedules", force: :cascade do |t|
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

  create_table "countries", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "nationality", default: "-"
  end

  create_table "course_classes", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "course_id"
    t.integer "professor_id"
    t.integer "year"
    t.integer "semester"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "not_schedulable", default: false, null: false
    t.string "obs_schedule"
    t.index ["course_id"], name: "index_course_classes_on_course_id"
    t.index ["professor_id"], name: "index_course_classes_on_professor_id"
  end

  create_table "course_research_areas", force: :cascade do |t|
    t.integer "course_id"
    t.integer "research_area_id"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["course_id"], name: "index_course_research_areas_on_course_id"
    t.index ["research_area_id"], name: "index_course_research_areas_on_research_area_id"
  end

  create_table "course_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "has_score", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "schedulable", default: true, null: false
    t.boolean "show_class_name", default: true, null: false
    t.boolean "allow_multiple_classes", default: false, null: false
    t.boolean "on_demand", default: false, null: false
  end

  create_table "courses", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.text "content"
    t.integer "credits"
    t.integer "course_type_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "workload"
    t.boolean "available", default: true, null: false
    t.index ["course_type_id"], name: "index_courses_on_course_type_id"
  end

  create_table "custom_variables", force: :cascade do |t|
    t.string "description", limit: 255
    t.string "variable", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "value"
  end

  create_table "deferral_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.integer "duration_semesters", default: 0
    t.integer "phase_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "duration_months", default: 0
    t.integer "duration_days", default: 0
    t.index ["phase_id"], name: "index_deferral_types_on_phase_id"
  end

  create_table "deferrals", force: :cascade do |t|
    t.date "approval_date"
    t.string "obs", limit: 255
    t.integer "enrollment_id"
    t.integer "deferral_type_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["deferral_type_id"], name: "index_deferrals_on_deferral_type_id"
    t.index ["enrollment_id"], name: "index_deferrals_on_enrollment_id"
  end

  create_table "dismissal_reasons", force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "show_advisor_name", default: false, null: false
    t.string "thesis_judgement", limit: 255
  end

  create_table "dismissals", force: :cascade do |t|
    t.date "date"
    t.integer "enrollment_id"
    t.integer "dismissal_reason_id"
    t.text "obs"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["dismissal_reason_id"], name: "index_dismissals_on_dismissal_reason_id"
    t.index ["enrollment_id"], name: "index_dismissals_on_enrollment_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name"
    t.string "to"
    t.string "subject"
    t.text "body"
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "enrollment_holds", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "year"
    t.integer "semester"
    t.integer "number_of_semesters", default: 1
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "active", default: true, null: false
    t.index ["enrollment_id"], name: "index_enrollment_holds_on_enrollment_id"
  end

  create_table "enrollment_request_comments", force: :cascade do |t|
    t.text "message"
    t.integer "enrollment_request_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_request_id"], name: "index_enrollment_request_comments_on_enrollment_request_id"
    t.index ["user_id"], name: "index_enrollment_request_comments_on_user_id"
  end

  create_table "enrollment_requests", force: :cascade do |t|
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

  create_table "enrollment_statuses", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "user", default: false, null: false
  end

  create_table "enrollments", force: :cascade do |t|
    t.string "enrollment_number", limit: 255
    t.integer "student_id"
    t.integer "level_id"
    t.integer "enrollment_status_id"
    t.date "admission_date"
    t.text "obs"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "thesis_title", limit: 255
    t.date "thesis_defense_date"
    t.integer "research_area_id"
    t.text "obs_to_academic_transcript"
    t.index ["enrollment_number"], name: "index_enrollments_on_enrollment_number"
    t.index ["enrollment_status_id"], name: "index_enrollments_on_enrollment_status_id"
    t.index ["level_id"], name: "index_enrollments_on_level_id"
    t.index ["research_area_id"], name: "index_enrollments_on_research_area_id"
    t.index ["student_id"], name: "index_enrollments_on_student_id"
  end

  create_table "filled_form_field_scholarities", force: :cascade do |t|
    t.integer "filled_form_field_id"
    t.string "level"
    t.string "status"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "start_date"
    t.string "institution"
    t.string "course"
    t.string "grade"
    t.string "location"
    t.string "grade_interval"
    t.index ["filled_form_field_id"], name: "index_filled_form_field_scholarities_on_filled_form_field_id"
  end

  create_table "filled_form_fields", force: :cascade do |t|
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

  create_table "filled_forms", force: :cascade do |t|
    t.integer "form_template_id"
    t.boolean "is_filled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["form_template_id"], name: "index_filled_forms_on_form_template_id"
  end

  create_table "form_conditions", force: :cascade do |t|
    t.string "field"
    t.string "condition"
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mode", default: "Condição"
    t.integer "parent_id"
    t.index ["field"], name: "index_form_conditions_on_field"
    t.index ["parent_id"], name: "index_form_conditions_on_parent_id"
  end

  create_table "form_fields", force: :cascade do |t|
    t.integer "form_template_id"
    t.integer "order"
    t.string "name"
    t.string "description"
    t.string "field_type"
    t.text "configuration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "sync"
    t.index ["form_template_id"], name: "index_form_fields_on_form_template_id"
  end

  create_table "form_templates", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "template_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grants", force: :cascade do |t|
    t.string "title"
    t.integer "start_year"
    t.integer "end_year"
    t.string "kind"
    t.string "funder"
    t.decimal "amount", precision: 14, scale: 2
    t.integer "professor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["professor_id"], name: "index_grants_on_professor_id"
  end

  create_table "institutions", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "code", limit: 255
  end

  create_table "letter_requests", force: :cascade do |t|
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

  create_table "levels", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "course_name", limit: 255
    t.integer "default_duration", default: 0
    t.boolean "show_advisements_points_in_list", default: false, null: false
    t.string "short_name_showed_in_list_header"
  end

  create_table "majors", force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "level_id"
    t.integer "institution_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["institution_id"], name: "index_majors_on_institution_id"
    t.index ["level_id"], name: "index_majors_on_level_id"
  end

  create_table "notification_logs", force: :cascade do |t|
    t.integer "notification_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "to", limit: 255
    t.string "subject", limit: 255
    t.text "body"
    t.string "attachments_file_names"
    t.string "reply_to", limit: 255
    t.index ["notification_id"], name: "index_notification_logs_on_notification_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "title", limit: 255
    t.string "to_template", limit: 255
    t.string "subject_template", limit: 255
    t.text "body_template"
    t.string "notification_offset", limit: 255
    t.string "query_offset", limit: 255
    t.string "frequency", limit: 255
    t.datetime "next_execution", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "individual", default: true, null: false
    t.integer "query_id", null: false
    t.boolean "has_grades_report_pdf_attachment", default: false, null: false
    t.index ["query_id"], name: "index_notifications_on_query_id"
  end

  create_table "paper_professors", force: :cascade do |t|
    t.integer "paper_id", null: false
    t.integer "professor_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["paper_id"], name: "index_paper_professors_on_paper_id"
    t.index ["professor_id"], name: "index_paper_professors_on_professor_id"
  end

  create_table "paper_students", force: :cascade do |t|
    t.integer "paper_id", null: false
    t.integer "student_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["paper_id"], name: "index_paper_students_on_paper_id"
    t.index ["student_id"], name: "index_paper_students_on_student_id"
  end

  create_table "papers", force: :cascade do |t|
    t.string "period"
    t.text "reference"
    t.string "kind"
    t.string "doi_issn_event"
    t.integer "owner_id", null: false
    t.text "other_authors"
    t.boolean "reason_impact_factor", default: false, null: false
    t.boolean "reason_international_list", default: false, null: false
    t.boolean "reason_citations", default: false, null: false
    t.boolean "reason_national_interest", default: false, null: false
    t.boolean "reason_international_interest", default: false, null: false
    t.boolean "reason_national_representativeness", default: false, null: false
    t.boolean "reason_scientific_contribution", default: false, null: false
    t.boolean "reason_tech_contribution", default: false, null: false
    t.boolean "reason_innovation_contribution", default: false, null: false
    t.boolean "reason_social_contribution", default: false, null: false
    t.text "reason_other"
    t.text "reason_justify"
    t.integer "order"
    t.text "other"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_papers_on_owner_id"
  end

  create_table "phase_completions", force: :cascade do |t|
    t.integer "enrollment_id"
    t.integer "phase_id"
    t.datetime "due_date", precision: nil
    t.datetime "completion_date", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_phase_completions_on_enrollment_id"
    t.index ["phase_id"], name: "index_phase_completions_on_phase_id"
  end

  create_table "phase_durations", force: :cascade do |t|
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

  create_table "phases", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "description", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "is_language", default: false, null: false
    t.boolean "extend_on_hold", default: false, null: false
    t.boolean "active", default: true, null: false
  end

  create_table "professor_research_areas", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "research_area_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["professor_id"], name: "index_professor_research_areas_on_professor_id"
    t.index ["research_area_id"], name: "index_professor_research_areas_on_research_area_id"
  end

  create_table "professors", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "cpf", limit: 255
    t.date "birthdate"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.index ["cpf"], name: "index_professors_on_cpf"
    t.index ["email"], name: "index_professors_on_email"
    t.index ["institution_id"], name: "index_professors_on_institution_id"
    t.index ["user_id"], name: "index_professors_on_user_id"
  end

  create_table "queries", force: :cascade do |t|
    t.string "name", limit: 255
    t.text "sql"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "description", limit: 255
  end

  create_table "query_params", force: :cascade do |t|
    t.integer "query_id"
    t.string "name", limit: 255
    t.string "default_value", limit: 255
    t.string "value_type", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["query_id"], name: "index_query_params_on_query_id"
  end

  create_table "ranking_columns", force: :cascade do |t|
    t.integer "ranking_config_id"
    t.string "name"
    t.string "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "admission_report_config_id"
    t.index ["admission_report_config_id"], name: "index_ranking_columns_on_admission_report_config_id"
    t.index ["ranking_config_id"], name: "index_ranking_columns_on_ranking_config_id"
  end

  create_table "ranking_configs", force: :cascade do |t|
    t.string "name"
    t.integer "form_template_id"
    t.integer "position_field_id"
    t.integer "machine_field_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "form_condition_id"
    t.string "behavior_on_invalid_condition", default: "Erro - apenas em seletores"
    t.string "behavior_on_invalid_ranking", default: "Erro"
    t.boolean "candidate_can_see", default: false, null: false
    t.index ["form_condition_id"], name: "index_ranking_configs_on_form_condition_id"
    t.index ["form_template_id"], name: "index_ranking_configs_on_form_template_id"
    t.index ["machine_field_id"], name: "index_ranking_configs_on_machine_field_id"
    t.index ["position_field_id"], name: "index_ranking_configs_on_position_field_id"
  end

  create_table "ranking_groups", force: :cascade do |t|
    t.integer "ranking_config_id"
    t.string "name"
    t.integer "vacancies"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ranking_config_id"], name: "index_ranking_groups_on_ranking_config_id"
  end

  create_table "ranking_machines", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "form_condition_id"
    t.index ["form_condition_id"], name: "index_ranking_machines_on_form_condition_id"
  end

  create_table "ranking_processes", force: :cascade do |t|
    t.integer "ranking_config_id"
    t.integer "order"
    t.integer "vacancies"
    t.string "group"
    t.integer "ranking_machine_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "step", default: 1
    t.index ["ranking_config_id"], name: "index_ranking_processes_on_ranking_config_id"
    t.index ["ranking_machine_id"], name: "index_ranking_processes_on_ranking_machine_id"
  end

  create_table "report_configurations", force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "use_at_report", default: false, null: false
    t.boolean "use_at_transcript", default: false, null: false
    t.boolean "use_at_grades_report", default: false, null: false
    t.boolean "use_at_schedule", default: false, null: false
    t.boolean "use_at_assertion", default: false, null: false
    t.text "text"
    t.string "image", limit: 255
    t.integer "order", default: 2
    t.decimal "scale", precision: 10, scale: 8
    t.integer "x"
    t.integer "y"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "signature_type", default: 0
    t.integer "expiration_in_months"
  end

  create_table "reports", force: :cascade do |t|
    t.integer "generated_by_id"
    t.integer "carrierwave_file_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "expires_at"
    t.string "identifier"
    t.string "file_name"
    t.index ["carrierwave_file_id"], name: "index_reports_on_carrierwave_file_id"
    t.index ["generated_by_id"], name: "index_reports_on_generated_by_id"
  end

  create_table "research_areas", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "description", limit: 255, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "scholarship_durations", force: :cascade do |t|
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

  create_table "scholarship_suspensions", force: :cascade do |t|
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true, null: false
    t.integer "scholarship_duration_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["scholarship_duration_id"], name: "index_scholarship_suspensions_on_scholarship_duration_id"
  end

  create_table "scholarship_types", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "scholarships", force: :cascade do |t|
    t.string "scholarship_number", limit: 255
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

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "sponsors", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
  end

  create_table "states", force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.integer "country_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
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
    t.integer "user_id", limit: 8
    t.index ["birth_city_id"], name: "index_students_on_birth_city_id"
    t.index ["birth_country_id"], name: "index_students_on_birth_country_id"
    t.index ["birth_state_id"], name: "index_students_on_state_id"
    t.index ["city_id"], name: "index_students_on_city_id"
    t.index ["cpf"], name: "index_students_on_cpf"
    t.index ["user_id"], name: "index_students_on_user_id"
  end

  create_table "thesis_defense_committee_participations", force: :cascade do |t|
    t.integer "professor_id"
    t.integer "enrollment_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["enrollment_id"], name: "index_thesis_defense_committee_participations_on_enrollment_id"
    t.index ["professor_id"], name: "index_thesis_defense_committee_participations_on_professor_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "email", limit: 255, default: "", null: false
    t.string "encrypted_password", limit: 255, default: "", null: false
    t.string "reset_password_token", limit: 255
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip", limit: 255
    t.string "last_sign_in_ip", limit: 255
    t.string "confirmation_token", limit: 255
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.integer "failed_attempts", default: 0
    t.string "unlock_token", limit: 255
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

  create_table "versions", force: :cascade do |t|
    t.string "item_type", limit: 255, null: false
    t.integer "item_id", null: false
    t.string "event", limit: 255, null: false
    t.string "whodunnit", limit: 255
    t.text "object", limit: 16777215
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "assertions", "queries"
  add_foreign_key "grants", "professors"
  add_foreign_key "paper_professors", "papers"
  add_foreign_key "paper_professors", "professors"
  add_foreign_key "paper_students", "papers"
  add_foreign_key "paper_students", "students"
  add_foreign_key "papers", "professors", column: "owner_id"
  add_foreign_key "reports", "carrier_wave_files", column: "carrierwave_file_id"
  add_foreign_key "reports", "users", column: "generated_by_id"
end