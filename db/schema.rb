# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20160729002508) do

  create_table "accomplishments", force: :cascade do |t|
    t.integer  "enrollment_id"
    t.integer  "phase_id"
    t.date     "conclusion_date"
    t.string   "obs",             limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "accomplishments", ["enrollment_id"], name: "index_accomplishments_on_enrollment_id"
  add_index "accomplishments", ["phase_id"], name: "index_accomplishments_on_phase_id"

  create_table "advisement_authorizations", force: :cascade do |t|
    t.integer  "professor_id"
    t.integer  "level_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "advisement_authorizations", ["level_id"], name: "index_advisement_authorizations_on_level_id"
  add_index "advisement_authorizations", ["professor_id"], name: "index_advisement_authorizations_on_professor_id"

  create_table "advisements", force: :cascade do |t|
    t.integer  "professor_id",                  null: false
    t.integer  "enrollment_id",                 null: false
    t.boolean  "main_advisor",  default: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "advisements", ["enrollment_id"], name: "index_advisements_on_enrollment_id"
  add_index "advisements", ["professor_id"], name: "index_advisements_on_professor_id"

  create_table "allocations", force: :cascade do |t|
    t.string   "day",             limit: 255
    t.string   "room",            limit: 255
    t.integer  "start_time"
    t.integer  "end_time"
    t.integer  "course_class_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "allocations", ["course_class_id"], name: "index_allocations_on_course_class_id"

  create_table "application_processes", force: :cascade do |t|
    t.string   "name"
    t.integer  "semester"
    t.integer  "year"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "form_template_id"
    t.integer  "letter_template_id"
    t.integer  "min_letters"
    t.integer  "max_letters"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.boolean  "is_enabled",         default: true
  end

  add_index "application_processes", ["form_template_id"], name: "index_application_processes_on_form_template_id"
  add_index "application_processes", ["letter_template_id"], name: "index_application_processes_on_letter_template_id"

  create_table "carrier_wave_files", force: :cascade do |t|
    t.string   "medium_hash", limit: 255
    t.binary   "binary"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "cities", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "state_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "cities", ["state_id"], name: "index_cities_on_state_id"

  create_table "class_enrollments", force: :cascade do |t|
    t.text     "obs"
    t.integer  "grade"
    t.string   "situation",              limit: 255
    t.integer  "course_class_id"
    t.integer  "enrollment_id"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "disapproved_by_absence",             default: false
  end

  add_index "class_enrollments", ["course_class_id"], name: "index_class_enrollments_on_course_class_id"
  add_index "class_enrollments", ["enrollment_id"], name: "index_class_enrollments_on_enrollment_id"

  create_table "countries", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.string   "nationality",             default: "-"
  end

  create_table "course_classes", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.integer  "course_id"
    t.integer  "professor_id"
    t.integer  "year"
    t.integer  "semester"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "course_classes", ["course_id"], name: "index_course_classes_on_course_id"
  add_index "course_classes", ["professor_id"], name: "index_course_classes_on_professor_id"

  create_table "course_research_areas", force: :cascade do |t|
    t.integer  "course_id"
    t.integer  "research_area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_types", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.boolean  "has_score"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "schedulable",                        default: true
    t.boolean  "show_class_name",                    default: true
    t.boolean  "allow_multiple_classes",             default: false, null: false
  end

  create_table "courses", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "code",           limit: 255
    t.text     "content"
    t.integer  "credits"
    t.integer  "course_type_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "workload"
    t.boolean  "available",                  default: true
  end

  add_index "courses", ["course_type_id"], name: "index_courses_on_course_type_id"

  create_table "custom_variables", force: :cascade do |t|
    t.string   "description", limit: 255
    t.string   "variable",    limit: 255
    t.text     "value",       limit: 255
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "deferral_types", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "description",        limit: 255
    t.integer  "duration_semesters",             default: 0
    t.integer  "phase_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "duration_months",                default: 0
    t.integer  "duration_days",                  default: 0
  end

  add_index "deferral_types", ["phase_id"], name: "index_deferral_types_on_phase_id"

  create_table "deferrals", force: :cascade do |t|
    t.date     "approval_date"
    t.string   "obs",              limit: 255
    t.integer  "enrollment_id"
    t.integer  "deferral_type_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "deferrals", ["deferral_type_id"], name: "index_deferrals_on_deferral_type_id"
  add_index "deferrals", ["enrollment_id"], name: "index_deferrals_on_enrollment_id"

  create_table "dismissal_reasons", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.text     "description"
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.boolean  "show_advisor_name",             default: false
    t.string   "thesis_judgement",  limit: 255
  end

  create_table "dismissals", force: :cascade do |t|
    t.date     "date"
    t.integer  "enrollment_id"
    t.integer  "dismissal_reason_id"
    t.text     "obs"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "dismissals", ["dismissal_reason_id"], name: "index_dismissals_on_dismissal_reason_id"
  add_index "dismissals", ["enrollment_id"], name: "index_dismissals_on_enrollment_id"

  create_table "enrollment_holds", force: :cascade do |t|
    t.integer  "enrollment_id"
    t.integer  "year"
    t.integer  "semester"
    t.integer  "number_of_semesters", default: 1
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "active",              default: true
  end

  add_index "enrollment_holds", ["enrollment_id"], name: "index_enrollment_holds_on_enrollment_id"

  create_table "enrollment_statuses", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "enrollments", force: :cascade do |t|
    t.string   "enrollment_number",    limit: 255
    t.integer  "student_id"
    t.integer  "level_id"
    t.integer  "enrollment_status_id"
    t.date     "admission_date"
    t.text     "obs"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "thesis_title",         limit: 255
    t.date     "thesis_defense_date"
    t.integer  "research_area_id"
  end

  add_index "enrollments", ["enrollment_status_id"], name: "index_enrollments_on_enrollment_status_id"
  add_index "enrollments", ["level_id"], name: "index_enrollments_on_level_id"
  add_index "enrollments", ["student_id"], name: "index_enrollments_on_student_id"

  create_table "form_field_inputs", force: :cascade do |t|
    t.integer  "student_application_id"
    t.integer  "form_field_id"
    t.string   "input"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "form_field_inputs", ["form_field_id"], name: "index_form_field_inputs_on_form_field_id"
  add_index "form_field_inputs", ["student_application_id"], name: "index_form_field_inputs_on_student_application_id"

  create_table "form_field_values", force: :cascade do |t|
    t.integer  "form_field_id"
    t.string   "value"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "form_field_values", ["form_field_id"], name: "index_form_field_values_on_form_field_id"

  create_table "form_fields", force: :cascade do |t|
    t.string   "field_type"
    t.string   "name"
    t.string   "description"
    t.boolean  "is_mandatory"
    t.integer  "form_template_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "form_fields", ["form_template_id"], name: "index_form_fields_on_form_template_id"

  create_table "form_file_uploads", force: :cascade do |t|
    t.integer  "student_application_id"
    t.integer  "form_field_id"
    t.string   "file"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "form_file_uploads", ["form_field_id"], name: "index_form_file_uploads_on_form_field_id"
  add_index "form_file_uploads", ["student_application_id"], name: "index_form_file_uploads_on_student_application_id"

  create_table "form_templates", force: :cascade do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_letter"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "status"
  end

  create_table "form_text_inputs", force: :cascade do |t|
    t.integer  "student_application_id"
    t.integer  "form_field_id"
    t.text     "input"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "form_text_inputs", ["form_field_id"], name: "index_form_text_inputs_on_form_field_id"
  add_index "form_text_inputs", ["student_application_id"], name: "index_form_text_inputs_on_student_application_id"

  create_table "institutions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "code",       limit: 255
  end

  create_table "letter_field_inputs", force: :cascade do |t|
    t.integer  "letter_request_id"
    t.integer  "form_field_id"
    t.string   "input"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "letter_field_inputs", ["form_field_id"], name: "index_letter_field_inputs_on_form_field_id"
  add_index "letter_field_inputs", ["letter_request_id"], name: "index_letter_field_inputs_on_letter_request_id"

  create_table "letter_file_uploads", force: :cascade do |t|
    t.integer  "letter_request_id"
    t.integer  "form_field_id"
    t.string   "file"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "letter_file_uploads", ["form_field_id"], name: "index_letter_file_uploads_on_form_field_id"
  add_index "letter_file_uploads", ["letter_request_id"], name: "index_letter_file_uploads_on_letter_request_id"

  create_table "letter_requests", force: :cascade do |t|
    t.integer  "student_application_id"
    t.string   "professor_name"
    t.string   "professor_email"
    t.string   "professor_telephone"
    t.string   "access_token"
    t.boolean  "is_filled"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "letter_requests", ["student_application_id"], name: "index_letter_requests_on_student_application_id"

  create_table "letter_text_inputs", force: :cascade do |t|
    t.integer  "letter_request_id"
    t.integer  "form_field_id"
    t.text     "input"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "letter_text_inputs", ["form_field_id"], name: "index_letter_text_inputs_on_form_field_id"
  add_index "letter_text_inputs", ["letter_request_id"], name: "index_letter_text_inputs_on_letter_request_id"

  create_table "levels", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.string   "course_name",      limit: 255
    t.integer  "default_duration",             default: 0
  end

  create_table "majors", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "level_id"
    t.integer  "institution_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "majors", ["institution_id"], name: "index_majors_on_institution_id"
  add_index "majors", ["level_id"], name: "index_majors_on_level_id"

  create_table "notification_logs", force: :cascade do |t|
    t.integer  "notification_id"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.string   "to",              limit: 255
    t.string   "subject",         limit: 255
    t.text     "body"
  end

  add_index "notification_logs", ["notification_id"], name: "index_notification_logs_on_notification_id"

  create_table "notification_params", force: :cascade do |t|
    t.integer  "notification_id"
    t.integer  "query_param_id"
    t.string   "value",           limit: 255
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.boolean  "active",                      default: false, null: false
  end

  add_index "notification_params", ["notification_id"], name: "index_notification_params_on_notification_id"
  add_index "notification_params", ["query_param_id"], name: "index_notification_params_on_query_param_id"

  create_table "notifications", force: :cascade do |t|
    t.string   "title",               limit: 255
    t.string   "to_template",         limit: 255
    t.string   "subject_template",    limit: 255
    t.text     "body_template"
    t.string   "notification_offset", limit: 255
    t.string   "query_offset",        limit: 255
    t.string   "frequency",           limit: 255
    t.datetime "next_execution"
    t.datetime "created_at",                                     null: false
    t.datetime "updated_at",                                     null: false
    t.boolean  "individual",                      default: true
    t.integer  "query_id",                                       null: false
  end

  create_table "phase_completions", force: :cascade do |t|
    t.integer  "enrollment_id"
    t.integer  "phase_id"
    t.datetime "due_date"
    t.datetime "completion_date"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  create_table "phase_durations", force: :cascade do |t|
    t.integer  "phase_id"
    t.integer  "level_id"
    t.integer  "deadline_semesters", default: 0
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.integer  "deadline_months",    default: 0
    t.integer  "deadline_days",      default: 0
  end

  add_index "phase_durations", ["level_id"], name: "index_phase_durations_on_level_id"
  add_index "phase_durations", ["phase_id"], name: "index_phase_durations_on_phase_id"

  create_table "phases", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "description",    limit: 255
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.boolean  "is_language",                default: false
    t.boolean  "extend_on_hold",             default: false
  end

  create_table "professor_research_areas", force: :cascade do |t|
    t.integer  "professor_id"
    t.integer  "research_area_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "professor_research_areas", ["professor_id"], name: "index_professor_research_areas_on_professor_id"
  add_index "professor_research_areas", ["research_area_id"], name: "index_professor_research_areas_on_research_area_id"

  create_table "professors", force: :cascade do |t|
    t.string   "name",                          limit: 255
    t.string   "cpf",                           limit: 255
    t.date     "birthdate"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "sex",                           limit: 255
    t.string   "civil_status",                  limit: 255
    t.string   "identity_number",               limit: 255
    t.string   "identity_issuing_body",         limit: 255
    t.string   "identity_expedition_date",      limit: 255
    t.string   "neighborhood",                  limit: 255
    t.string   "address",                       limit: 255
    t.integer  "city_id"
    t.string   "zip_code",                      limit: 255
    t.string   "telephone1",                    limit: 255
    t.string   "telephone2",                    limit: 255
    t.string   "siape",                         limit: 255
    t.string   "enrollment_number",             limit: 255
    t.string   "identity_issuing_place",        limit: 255
    t.integer  "institution_id"
    t.string   "email",                         limit: 255
    t.date     "academic_title_date"
    t.integer  "academic_title_country_id"
    t.integer  "academic_title_institution_id"
    t.integer  "academic_title_level_id"
    t.text     "obs"
  end

  add_index "professors", ["academic_title_country_id"], name: "index_professors_on_academic_title_country_id"
  add_index "professors", ["academic_title_institution_id"], name: "index_professors_on_academic_title_institution_id"
  add_index "professors", ["academic_title_level_id"], name: "index_professors_on_academic_title_level_id"
  add_index "professors", ["city_id"], name: "index_professors_on_city_id"
  add_index "professors", ["email"], name: "index_professors_on_email"
  add_index "professors", ["institution_id"], name: "index_professors_on_institution_id"

  create_table "queries", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "sql"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "description", limit: 255
  end

  create_table "query_params", force: :cascade do |t|
    t.integer  "query_id"
    t.string   "name",          limit: 255
    t.string   "default_value", limit: 255
    t.string   "value_type",    limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "query_params", ["query_id"], name: "index_query_params_on_query_id"

  create_table "report_configurations", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.boolean  "use_at_report"
    t.boolean  "use_at_transcript"
    t.boolean  "use_at_grades_report"
    t.boolean  "use_at_schedule"
    t.text     "text"
    t.string   "image",                limit: 255
    t.boolean  "signature_footer"
    t.integer  "order",                                                     default: 2
    t.decimal  "scale",                            precision: 10, scale: 8
    t.integer  "x"
    t.integer  "y"
    t.datetime "created_at",                                                            null: false
    t.datetime "updated_at",                                                            null: false
  end

  create_table "research_areas", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "code",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",        limit: 50,  null: false
    t.string   "description", limit: 255, null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "scholarship_durations", force: :cascade do |t|
    t.integer  "scholarship_id", null: false
    t.integer  "enrollment_id",  null: false
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.date     "cancel_date"
  end

  add_index "scholarship_durations", ["enrollment_id"], name: "index_scholarship_durations_on_enrollment_id"
  add_index "scholarship_durations", ["scholarship_id"], name: "index_scholarship_durations_on_scholarship_id"

  create_table "scholarship_suspensions", force: :cascade do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "active",                  default: true
    t.integer  "scholarship_duration_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "scholarship_suspensions", ["scholarship_duration_id"], name: "index_scholarship_suspensions_on_scholarship_duration_id"

  create_table "scholarship_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "scholarships", force: :cascade do |t|
    t.string   "scholarship_number",  limit: 255
    t.integer  "level_id"
    t.integer  "sponsor_id"
    t.integer  "scholarship_type_id"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs"
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.integer  "professor_id"
  end

  add_index "scholarships", ["level_id"], name: "index_scholarships_on_level_id"
  add_index "scholarships", ["professor_id"], name: "index_scholarships_on_professor_id"
  add_index "scholarships", ["scholarship_type_id"], name: "index_scholarships_on_scholarship_type_id"
  add_index "scholarships", ["sponsor_id"], name: "index_scholarships_on_sponsor_id"

  create_table "sponsors", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "states", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "code",       limit: 255
    t.integer  "country_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "states", ["country_id"], name: "index_states_on_country_id"

  create_table "student_applications", force: :cascade do |t|
    t.integer  "student_id"
    t.integer  "application_process_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "student_applications", ["application_process_id"], name: "index_student_applications_on_application_process_id"
  add_index "student_applications", ["student_id"], name: "index_student_applications_on_student_id"

  create_table "student_majors", force: :cascade do |t|
    t.integer "major_id",   null: false
    t.integer "student_id", null: false
  end

  add_index "student_majors", ["major_id"], name: "index_student_majors_on_major_id"
  add_index "student_majors", ["student_id"], name: "index_student_majors_on_student_id"

  create_table "student_tokens", force: :cascade do |t|
    t.integer  "application_process_id"
    t.integer  "student_id"
    t.string   "token"
    t.boolean  "is_used"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "cpf"
    t.string   "email"
    t.integer  "student_application_id"
  end

  add_index "student_tokens", ["application_process_id"], name: "index_student_tokens_on_application_process_id"
  add_index "student_tokens", ["student_application_id"], name: "index_student_tokens_on_student_application_id"
  add_index "student_tokens", ["student_id"], name: "index_student_tokens_on_student_id"

  create_table "students", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.string   "cpf",                      limit: 255
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.text     "obs"
    t.date     "birthdate"
    t.string   "sex",                      limit: 255
    t.string   "civil_status",             limit: 255
    t.string   "father_name",              limit: 255
    t.string   "mother_name",              limit: 255
    t.string   "identity_number",          limit: 255
    t.string   "identity_issuing_body",    limit: 255
    t.date     "identity_expedition_date"
    t.string   "employer",                 limit: 255
    t.string   "job_position",             limit: 255
    t.integer  "birth_state_id"
    t.integer  "city_id"
    t.string   "neighborhood",             limit: 255
    t.string   "zip_code",                 limit: 255
    t.string   "address",                  limit: 255
    t.string   "telephone1",               limit: 255
    t.string   "telephone2",               limit: 255
    t.string   "email",                    limit: 255
    t.integer  "birth_city_id"
    t.string   "identity_issuing_place",   limit: 255
    t.string   "photo",                    limit: 255
  end

  add_index "students", ["birth_city_id"], name: "index_students_on_birth_city_id"
  add_index "students", ["birth_state_id"], name: "index_students_on_state_id"
  add_index "students", ["city_id"], name: "index_students_on_city_id"

  create_table "thesis_defense_committee_participations", force: :cascade do |t|
    t.integer  "professor_id"
    t.integer  "enrollment_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "thesis_defense_committee_participations", ["enrollment_id"], name: "index_thesis_defense_committee_participations_on_enrollment_id"
  add_index "thesis_defense_committee_participations", ["professor_id"], name: "index_thesis_defense_committee_participations_on_professor_id"

  create_table "users", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.string   "hashed_password",        limit: 255
    t.string   "salt",                   limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",                    default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.integer  "role_id",                            default: 1,  null: false
  end

  add_index "users", ["email"], name: "index_users_on_email"
  add_index "users", ["role_id"], name: "index_users_on_role_id"

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255, null: false
    t.integer  "item_id",                null: false
    t.string   "event",      limit: 255, null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"

end
