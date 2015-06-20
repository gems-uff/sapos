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

ActiveRecord::Schema.define(version: 20150428212151) do

  create_table "accomplishments", force: :cascade do |t|
    t.integer  "enrollment_id",   limit: 4
    t.integer  "phase_id",        limit: 4
    t.date     "conclusion_date"
    t.string   "obs",             limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "accomplishments", ["enrollment_id"], name: "index_accomplishments_on_enrollment_id", using: :btree
  add_index "accomplishments", ["phase_id"], name: "index_accomplishments_on_phase_id", using: :btree

  create_table "advisement_authorizations", force: :cascade do |t|
    t.integer  "professor_id", limit: 4
    t.integer  "level_id",     limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "advisement_authorizations", ["level_id"], name: "index_advisement_authorizations_on_level_id", using: :btree
  add_index "advisement_authorizations", ["professor_id"], name: "index_advisement_authorizations_on_professor_id", using: :btree

  create_table "advisements", force: :cascade do |t|
    t.integer  "professor_id",  limit: 4, null: false
    t.integer  "enrollment_id", limit: 4, null: false
    t.boolean  "main_advisor",  limit: 1
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  add_index "advisements", ["enrollment_id"], name: "index_advisements_on_enrollment_id", using: :btree
  add_index "advisements", ["professor_id"], name: "index_advisements_on_professor_id", using: :btree

  create_table "allocations", force: :cascade do |t|
    t.string   "day",             limit: 255
    t.string   "room",            limit: 255
    t.integer  "start_time",      limit: 4
    t.integer  "end_time",        limit: 4
    t.integer  "course_class_id", limit: 4
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "allocations", ["course_class_id"], name: "index_allocations_on_course_class_id", using: :btree

  create_table "carrier_wave_files", force: :cascade do |t|
    t.string   "identifier",  limit: 255
    t.string   "medium_hash", limit: 255
    t.binary   "binary",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "cities", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "state_id",   limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "cities", ["state_id"], name: "index_cities_on_state_id", using: :btree

  create_table "class_enrollments", force: :cascade do |t|
    t.text     "obs",                    limit: 65535
    t.integer  "grade",                  limit: 4
    t.string   "situation",              limit: 255
    t.integer  "course_class_id",        limit: 4
    t.integer  "enrollment_id",          limit: 4
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
    t.boolean  "disapproved_by_absence", limit: 1,     default: false
  end

  add_index "class_enrollments", ["course_class_id"], name: "index_class_enrollments_on_course_class_id", using: :btree
  add_index "class_enrollments", ["enrollment_id"], name: "index_class_enrollments_on_enrollment_id", using: :btree

  create_table "countries", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "nationality", default: "-"
  end

  create_table "course_classes", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.integer  "course_id",    limit: 4
    t.integer  "professor_id", limit: 4
    t.integer  "year",         limit: 4
    t.integer  "semester",     limit: 4
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "course_classes", ["course_id"], name: "index_course_classes_on_course_id", using: :btree
  add_index "course_classes", ["professor_id"], name: "index_course_classes_on_professor_id", using: :btree

  create_table "course_research_areas", force: :cascade do |t|
    t.integer  "course_id",        limit: 4
    t.integer  "research_area_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "course_types", force: :cascade do |t|
    t.string   "name",                   limit: 255
    t.boolean  "has_score",              limit: 1
    t.boolean  "allow_multiple_classes", limit: 1,   default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "schedulable",            limit: 1,   default: true
    t.boolean  "show_class_name",        limit: 1,   default: true
  end

  create_table "courses", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "code",           limit: 255
    t.text     "content",        limit: 65535
    t.integer  "credits",        limit: 4
    t.integer  "course_type_id", limit: 4
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "workload",       limit: 4
    t.boolean  "available",      limit: 1,     default: true
  end

  add_index "courses", ["course_type_id"], name: "index_courses_on_course_type_id", using: :btree

  create_table "custom_variables", force: :cascade do |t|
    t.string   "description", limit: 255
    t.string   "variable",    limit: 255
    t.text     "value",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "deferral_types", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.string   "description",        limit: 255
    t.integer  "duration_semesters", limit: 4,   default: 0
    t.integer  "phase_id",           limit: 4
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "duration_months",    limit: 4,   default: 0
    t.integer  "duration_days",      limit: 4,   default: 0
  end

  add_index "deferral_types", ["phase_id"], name: "index_deferral_types_on_phase_id", using: :btree

  create_table "deferrals", force: :cascade do |t|
    t.date     "approval_date"
    t.string   "obs",              limit: 255
    t.integer  "enrollment_id",    limit: 4
    t.integer  "deferral_type_id", limit: 4
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "deferrals", ["deferral_type_id"], name: "index_deferrals_on_deferral_type_id", using: :btree
  add_index "deferrals", ["enrollment_id"], name: "index_deferrals_on_enrollment_id", using: :btree

  create_table "dismissal_reasons", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.text     "description",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "show_advisor_name", limit: 1,     default: false
    t.string   "thesis_judgement",  limit: 255
  end

  create_table "dismissals", force: :cascade do |t|
    t.date     "date"
    t.integer  "enrollment_id",       limit: 4
    t.integer  "dismissal_reason_id", limit: 4
    t.text     "obs",                 limit: 65535
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "dismissals", ["dismissal_reason_id"], name: "index_dismissals_on_dismissal_reason_id", using: :btree
  add_index "dismissals", ["enrollment_id"], name: "index_dismissals_on_enrollment_id", using: :btree

  create_table "enrollment_holds", force: :cascade do |t|
    t.integer  "enrollment_id",       limit: 4
    t.integer  "year",                limit: 4
    t.integer  "semester",            limit: 4
    t.integer  "number_of_semesters", limit: 4, default: 1
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",              limit: 1, default: true
  end

  add_index "enrollment_holds", ["enrollment_id"], name: "index_enrollment_holds_on_enrollment_id", using: :btree

  create_table "enrollment_statuses", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "enrollments", force: :cascade do |t|
    t.string   "enrollment_number",    limit: 255
    t.integer  "student_id",           limit: 4
    t.integer  "level_id",             limit: 4
    t.integer  "enrollment_status_id", limit: 4
    t.date     "admission_date"
    t.text     "obs",                  limit: 65535
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "thesis_title",         limit: 255
    t.date     "thesis_defense_date"
    t.integer  "research_area_id",     limit: 4
  end

  add_index "enrollments", ["enrollment_status_id"], name: "index_enrollments_on_enrollment_status_id", using: :btree
  add_index "enrollments", ["level_id"], name: "index_enrollments_on_level_id", using: :btree
  add_index "enrollments", ["student_id"], name: "index_enrollments_on_student_id", using: :btree

  create_table "institutions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code",       limit: 255
  end

  create_table "levels", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "course_name",      limit: 255
    t.integer  "default_duration", limit: 4,   default: 0
  end

  create_table "majors", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.integer  "level_id",       limit: 4
    t.integer  "institution_id", limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "majors", ["institution_id"], name: "index_majors_on_institution_id", using: :btree
  add_index "majors", ["level_id"], name: "index_majors_on_level_id", using: :btree

  create_table "notification_logs", force: :cascade do |t|
    t.integer  "notification_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "to",              limit: 255
    t.string   "subject",         limit: 255
    t.text     "body",            limit: 65535
  end

  add_index "notification_logs", ["notification_id"], name: "index_notification_logs_on_notification_id", using: :btree

  create_table "notification_params", force: :cascade do |t|
    t.boolean  "active",          limit: 1,   default: false, null: false
    t.integer  "notification_id", limit: 4
    t.integer  "query_param_id",  limit: 4
    t.string   "value",           limit: 255
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "notification_params", ["notification_id"], name: "index_notification_params_on_notification_id", using: :btree
  add_index "notification_params", ["query_param_id"], name: "index_notification_params_on_query_param_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.integer  "query_id",            limit: 4,                    null: false
    t.string   "title",               limit: 255
    t.string   "to_template",         limit: 255
    t.string   "subject_template",    limit: 255
    t.text     "body_template",       limit: 65535
    t.string   "notification_offset", limit: 255
    t.string   "query_offset",        limit: 255
    t.string   "frequency",           limit: 255
    t.datetime "next_execution"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "individual",          limit: 1,     default: true
  end

  create_table "phase_completions", force: :cascade do |t|
    t.integer  "enrollment_id",   limit: 4
    t.integer  "phase_id",        limit: 4
    t.datetime "due_date"
    t.datetime "completion_date"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phase_durations", force: :cascade do |t|
    t.integer  "phase_id",           limit: 4
    t.integer  "level_id",           limit: 4
    t.integer  "deadline_semesters", limit: 4, default: 0
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "deadline_months",    limit: 4, default: 0
    t.integer  "deadline_days",      limit: 4, default: 0
  end

  add_index "phase_durations", ["level_id"], name: "index_phase_durations_on_level_id", using: :btree
  add_index "phase_durations", ["phase_id"], name: "index_phase_durations_on_phase_id", using: :btree

  create_table "phases", force: :cascade do |t|
    t.string   "name",           limit: 255
    t.string   "description",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_language",    limit: 1,   default: false
    t.boolean  "extend_on_hold", limit: 1,   default: false
  end

  create_table "professor_research_areas", force: :cascade do |t|
    t.integer  "professor_id",     limit: 4
    t.integer  "research_area_id", limit: 4
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "professor_research_areas", ["professor_id"], name: "index_professor_research_areas_on_professor_id", using: :btree
  add_index "professor_research_areas", ["research_area_id"], name: "index_professor_research_areas_on_research_area_id", using: :btree

  create_table "professors", force: :cascade do |t|
    t.string   "name",                          limit: 255
    t.string   "cpf",                           limit: 255
    t.date     "birthdate"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.string   "sex",                           limit: 255
    t.string   "civil_status",                  limit: 255
    t.string   "identity_number",               limit: 255
    t.string   "identity_issuing_body",         limit: 255
    t.string   "identity_expedition_date",      limit: 255
    t.string   "neighborhood",                  limit: 255
    t.string   "address",                       limit: 255
    t.integer  "city_id",                       limit: 4
    t.string   "zip_code",                      limit: 255
    t.string   "telephone1",                    limit: 255
    t.string   "telephone2",                    limit: 255
    t.string   "siape",                         limit: 255
    t.string   "enrollment_number",             limit: 255
    t.string   "identity_issuing_place",        limit: 255
    t.integer  "institution_id",                limit: 4
    t.string   "email",                         limit: 255
    t.date     "academic_title_date"
    t.integer  "academic_title_country_id",     limit: 4
    t.integer  "academic_title_institution_id", limit: 4
    t.integer  "academic_title_level_id",       limit: 4
    t.text     "obs",                           limit: 65535
  end

  add_index "professors", ["academic_title_country_id"], name: "index_professors_on_academic_title_country_id", using: :btree
  add_index "professors", ["academic_title_institution_id"], name: "index_professors_on_academic_title_institution_id", using: :btree
  add_index "professors", ["academic_title_level_id"], name: "index_professors_on_academic_title_level_id", using: :btree
  add_index "professors", ["city_id"], name: "index_professors_on_city_id", using: :btree
  add_index "professors", ["email"], name: "index_professors_on_email", using: :btree
  add_index "professors", ["institution_id"], name: "index_professors_on_institution_id", using: :btree

  create_table "queries", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.text     "sql",         limit: 65535
    t.string   "description", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "query_params", force: :cascade do |t|
    t.integer  "query_id",      limit: 4
    t.string   "name",          limit: 255
    t.string   "default_value", limit: 255
    t.string   "value_type",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "query_params", ["query_id"], name: "index_query_params_on_query_id", using: :btree

  create_table "report_configurations", force: :cascade do |t|
    t.string   "name",                 limit: 255
    t.boolean  "use_at_report",        limit: 1
    t.boolean  "use_at_transcript",    limit: 1
    t.boolean  "use_at_grades_report", limit: 1
    t.boolean  "use_at_schedule",      limit: 1
    t.text     "text",                 limit: 65535
    t.string   "image",                limit: 255
    t.boolean  "signature_footer",     limit: 1
    t.integer  "order",                limit: 4,                              default: 2
    t.decimal  "scale",                              precision: 10, scale: 8
    t.integer  "x",                    limit: 4
    t.integer  "y",                    limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "research_areas", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "code",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",        limit: 50,  null: false
    t.string   "description", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scholarship_durations", force: :cascade do |t|
    t.integer  "scholarship_id", limit: 4,     null: false
    t.integer  "enrollment_id",  limit: 4,     null: false
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs",            limit: 65535
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.date     "cancel_date"
  end

  add_index "scholarship_durations", ["enrollment_id"], name: "index_scholarship_durations_on_enrollment_id", using: :btree
  add_index "scholarship_durations", ["scholarship_id"], name: "index_scholarship_durations_on_scholarship_id", using: :btree

  create_table "scholarship_suspensions", force: :cascade do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "active",                  limit: 1, default: true
    t.integer  "scholarship_duration_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "scholarship_suspensions", ["scholarship_duration_id"], name: "index_scholarship_suspensions_on_scholarship_duration_id", using: :btree

  create_table "scholarship_types", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scholarships", force: :cascade do |t|
    t.string   "scholarship_number",  limit: 255
    t.integer  "level_id",            limit: 4
    t.integer  "sponsor_id",          limit: 4
    t.integer  "scholarship_type_id", limit: 4
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs",                 limit: 65535
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.integer  "professor_id",        limit: 4
  end

  add_index "scholarships", ["level_id"], name: "index_scholarships_on_level_id", using: :btree
  add_index "scholarships", ["professor_id"], name: "index_scholarships_on_professor_id", using: :btree
  add_index "scholarships", ["scholarship_type_id"], name: "index_scholarships_on_scholarship_type_id", using: :btree
  add_index "scholarships", ["sponsor_id"], name: "index_scholarships_on_sponsor_id", using: :btree

  create_table "sponsors", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "states", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "code",       limit: 255
    t.integer  "country_id", limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "states", ["country_id"], name: "index_states_on_country_id", using: :btree

  create_table "student_majors", force: :cascade do |t|
    t.integer "major_id",   limit: 4, null: false
    t.integer "student_id", limit: 4, null: false
  end

  add_index "student_majors", ["major_id"], name: "index_student_majors_on_major_id", using: :btree
  add_index "student_majors", ["student_id"], name: "index_student_majors_on_student_id", using: :btree

  create_table "students", force: :cascade do |t|
    t.string   "name",                     limit: 255
    t.string   "cpf",                      limit: 255
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.text     "obs",                      limit: 65535
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
    t.integer  "birth_state_id",           limit: 4
    t.integer  "city_id",                  limit: 4
    t.string   "neighborhood",             limit: 255
    t.string   "zip_code",                 limit: 255
    t.string   "address",                  limit: 255
    t.string   "telephone1",               limit: 255
    t.string   "telephone2",               limit: 255
    t.string   "email",                    limit: 255
    t.integer  "birth_city_id",            limit: 4
    t.string   "identity_issuing_place",   limit: 255
    t.string   "photo",                    limit: 255
  end

  add_index "students", ["birth_city_id"], name: "index_students_on_birth_city_id", using: :btree
  add_index "students", ["birth_state_id"], name: "index_students_on_birth_state_id", using: :btree
  add_index "students", ["city_id"], name: "index_students_on_city_id", using: :btree

  create_table "thesis_defense_committee_participations", force: :cascade do |t|
    t.integer  "professor_id",  limit: 4
    t.integer  "enrollment_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "thesis_defense_committee_participations", ["enrollment_id"], name: "index_thesis_defense_committee_participations_on_enrollment_id", using: :btree
  add_index "thesis_defense_committee_participations", ["professor_id"], name: "index_thesis_defense_committee_participations_on_professor_id", using: :btree

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
    t.integer  "sign_in_count",          limit: 4,   default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",        limit: 4,   default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.integer  "role_id",                limit: 4,   default: 1,  null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["role_id"], name: "index_users_on_role_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255,   null: false
    t.integer  "item_id",    limit: 4,     null: false
    t.string   "event",      limit: 255,   null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object",     limit: 65535
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
