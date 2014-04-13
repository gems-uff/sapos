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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140413210104) do

  create_table "accomplishments", :force => true do |t|
    t.integer  "enrollment_id"
    t.integer  "phase_id"
    t.date     "conclusion_date"
    t.string   "obs"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "accomplishments", ["enrollment_id"], :name => "index_accomplishments_on_enrollment_id"
  add_index "accomplishments", ["phase_id"], :name => "index_accomplishments_on_phase_id"

  create_table "advisement_authorizations", :force => true do |t|
    t.integer  "professor_id"
    t.integer  "level_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "advisement_authorizations", ["level_id"], :name => "index_advisement_authorizations_on_level_id"
  add_index "advisement_authorizations", ["professor_id"], :name => "index_advisement_authorizations_on_professor_id"

  create_table "advisements", :force => true do |t|
    t.integer  "professor_id",  :null => false
    t.integer  "enrollment_id", :null => false
    t.boolean  "main_advisor"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "advisements", ["enrollment_id"], :name => "index_advisements_on_enrollment_id"
  add_index "advisements", ["professor_id"], :name => "index_advisements_on_professor_id"

  create_table "allocations", :force => true do |t|
    t.string   "day"
    t.string   "room"
    t.integer  "start_time"
    t.integer  "end_time"
    t.integer  "course_class_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "allocations", ["course_class_id"], :name => "index_allocations_on_course_class_id"

  create_table "cities", :force => true do |t|
    t.string   "name"
    t.integer  "state_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "cities", ["state_id"], :name => "index_cities_on_state_id"

  create_table "class_enrollments", :force => true do |t|
    t.text     "obs"
    t.integer  "grade"
    t.string   "situation"
    t.integer  "course_class_id"
    t.integer  "enrollment_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "disapproved_by_absence", :default => false
  end

  add_index "class_enrollments", ["course_class_id"], :name => "index_class_enrollments_on_course_class_id"
  add_index "class_enrollments", ["enrollment_id"], :name => "index_class_enrollments_on_enrollment_id"

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "course_classes", :force => true do |t|
    t.string   "name"
    t.integer  "course_id"
    t.integer  "professor_id"
    t.integer  "year"
    t.integer  "semester"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "course_classes", ["course_id"], :name => "index_course_classes_on_course_id"
  add_index "course_classes", ["professor_id"], :name => "index_course_classes_on_professor_id"

  create_table "course_types", :force => true do |t|
    t.string   "name"
    t.boolean  "has_score"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "schedulable"
    t.boolean  "show_class_name"
    t.boolean  "allow_multiple_classes", :default => false, :null => false
  end

  create_table "courses", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.text     "content"
    t.integer  "credits"
    t.integer  "research_area_id"
    t.integer  "course_type_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "workload"
  end

  add_index "courses", ["course_type_id"], :name => "index_courses_on_course_type_id"
  add_index "courses", ["research_area_id"], :name => "index_courses_on_research_area_id"

  create_table "custom_variables", :force => true do |t|
    t.string   "name"
    t.string   "variable"
    t.text     "value",      :limit => 255
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "deferral_types", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "duration_semesters", :default => 0
    t.integer  "phase_id"
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "duration_months",    :default => 0
    t.integer  "duration_days",      :default => 0
  end

  add_index "deferral_types", ["phase_id"], :name => "index_deferral_types_on_phase_id"

  create_table "deferrals", :force => true do |t|
    t.date     "approval_date"
    t.string   "obs"
    t.integer  "enrollment_id"
    t.integer  "deferral_type_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "deferrals", ["deferral_type_id"], :name => "index_deferrals_on_deferral_type_id"
  add_index "deferrals", ["enrollment_id"], :name => "index_deferrals_on_enrollment_id"

  create_table "dismissal_reasons", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "show_advisor_name", :default => false
    t.string   "thesis_judgement"
  end

  create_table "dismissals", :force => true do |t|
    t.date     "date"
    t.integer  "enrollment_id"
    t.integer  "dismissal_reason_id"
    t.text     "obs"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "dismissals", ["dismissal_reason_id"], :name => "index_dismissals_on_dismissal_reason_id"
  add_index "dismissals", ["enrollment_id"], :name => "index_dismissals_on_enrollment_id"

  create_table "enrollment_statuses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "enrollments", :force => true do |t|
    t.string   "enrollment_number"
    t.integer  "student_id"
    t.integer  "level_id"
    t.integer  "enrollment_status_id"
    t.date     "admission_date"
    t.text     "obs"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "thesis_title"
    t.date     "thesis_defense_date"
    t.integer  "research_area_id"
  end

  add_index "enrollments", ["enrollment_status_id"], :name => "index_enrollments_on_enrollment_status_id"
  add_index "enrollments", ["level_id"], :name => "index_enrollments_on_level_id"
  add_index "enrollments", ["student_id"], :name => "index_enrollments_on_student_id"

  create_table "institutions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "code"
  end

  create_table "levels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "majors", :force => true do |t|
    t.string   "name"
    t.integer  "level_id"
    t.integer  "institution_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "majors", ["institution_id"], :name => "index_majors_on_institution_id"
  add_index "majors", ["level_id"], :name => "index_majors_on_level_id"

  create_table "notification_logs", :force => true do |t|
    t.integer  "notification_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.string   "to"
    t.string   "subject"
    t.text     "body"
  end

  add_index "notification_logs", ["notification_id"], :name => "index_notification_logs_on_notification_id"

  create_table "notifications", :force => true do |t|
    t.string   "title"
    t.string   "to_template"
    t.string   "subject_template"
    t.text     "body_template"
    t.string   "notification_offset"
    t.string   "query_offset"
    t.string   "frequency"
    t.datetime "next_execution"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.boolean  "individual",          :default => true
    t.integer  "query_id",                              :null => false
  end

  create_table "phase_completions", :force => true do |t|
    t.integer  "enrollment_id"
    t.integer  "phase_id"
    t.datetime "due_date"
    t.datetime "completion_date"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "phase_durations", :force => true do |t|
    t.integer  "phase_id"
    t.integer  "level_id"
    t.integer  "deadline_semesters", :default => 0
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "deadline_months",    :default => 0
    t.integer  "deadline_days",      :default => 0
  end

  add_index "phase_durations", ["level_id"], :name => "index_phase_durations_on_level_id"
  add_index "phase_durations", ["phase_id"], :name => "index_phase_durations_on_phase_id"

  create_table "phases", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.boolean  "is_language", :default => false
  end

  create_table "professor_research_areas", :force => true do |t|
    t.integer  "professor_id"
    t.integer  "research_area_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "professor_research_areas", ["professor_id"], :name => "index_professor_research_areas_on_professor_id"
  add_index "professor_research_areas", ["research_area_id"], :name => "index_professor_research_areas_on_research_area_id"

  create_table "professors", :force => true do |t|
    t.string   "name"
    t.string   "cpf"
    t.date     "birthdate"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "sex"
    t.string   "civil_status"
    t.string   "identity_number"
    t.string   "identity_issuing_body"
    t.string   "identity_expedition_date"
    t.string   "neighborhood"
    t.string   "address"
    t.integer  "city_id"
    t.string   "zip_code"
    t.string   "telephone1"
    t.string   "telephone2"
    t.string   "siape"
    t.string   "enrollment_number"
    t.string   "identity_issuing_place"
    t.integer  "institution_id"
    t.string   "email"
  end

  add_index "professors", ["city_id"], :name => "index_professors_on_city_id"
  add_index "professors", ["email"], :name => "index_professors_on_email"
  add_index "professors", ["institution_id"], :name => "index_professors_on_institution_id"

  create_table "queries", :force => true do |t|
    t.string   "name"
    t.text     "sql"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "research_areas", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.string   "description",               :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "scholarship_durations", :force => true do |t|
    t.integer  "scholarship_id", :null => false
    t.integer  "enrollment_id",  :null => false
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.date     "cancel_date"
  end

  add_index "scholarship_durations", ["enrollment_id"], :name => "index_scholarship_durations_on_enrollment_id"
  add_index "scholarship_durations", ["scholarship_id"], :name => "index_scholarship_durations_on_scholarship_id"

  create_table "scholarship_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "scholarships", :force => true do |t|
    t.string   "scholarship_number"
    t.integer  "level_id"
    t.integer  "sponsor_id"
    t.integer  "scholarship_type_id"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.integer  "professor_id"
  end

  add_index "scholarships", ["level_id"], :name => "index_scholarships_on_level_id"
  add_index "scholarships", ["professor_id"], :name => "index_scholarships_on_professor_id"
  add_index "scholarships", ["scholarship_type_id"], :name => "index_scholarships_on_scholarship_type_id"
  add_index "scholarships", ["sponsor_id"], :name => "index_scholarships_on_sponsor_id"

  create_table "sponsors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "states", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "country_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "states", ["country_id"], :name => "index_states_on_country_id"

  create_table "student_majors", :force => true do |t|
    t.integer "major_id",   :null => false
    t.integer "student_id", :null => false
  end

  add_index "student_majors", ["major_id"], :name => "index_student_majors_on_major_id"
  add_index "student_majors", ["student_id"], :name => "index_student_majors_on_student_id"

  create_table "students", :force => true do |t|
    t.string   "name"
    t.string   "cpf"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.text     "obs"
    t.date     "birthdate"
    t.string   "sex"
    t.string   "civil_status"
    t.string   "father_name"
    t.string   "mother_name"
    t.string   "identity_number"
    t.string   "identity_issuing_body"
    t.date     "identity_expedition_date"
    t.string   "employer"
    t.string   "job_position"
    t.integer  "birth_state_id"
    t.integer  "city_id"
    t.string   "neighborhood"
    t.string   "zip_code"
    t.string   "address"
    t.string   "telephone1"
    t.string   "telephone2"
    t.string   "email"
    t.integer  "birth_city_id"
    t.string   "identity_issuing_place"
  end

  add_index "students", ["birth_city_id"], :name => "index_students_on_birth_city_id"
  add_index "students", ["birth_state_id"], :name => "index_students_on_state_id"
  add_index "students", ["city_id"], :name => "index_students_on_city_id"

  create_table "thesis_defense_committee_participations", :force => true do |t|
    t.integer  "professor_id"
    t.integer  "enrollment_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "thesis_defense_committee_participations", ["enrollment_id"], :name => "index_thesis_defense_committee_participations_on_enrollment_id"
  add_index "thesis_defense_committee_participations", ["professor_id"], :name => "index_thesis_defense_committee_participations_on_professor_id"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "hashed_password"
    t.string   "salt"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "failed_attempts",        :default => 0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.integer  "role_id",                :default => 1,  :null => false
  end

  add_index "users", ["email"], :name => "index_users_on_email"
  add_index "users", ["role_id"], :name => "index_users_on_role_id"

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"

end
