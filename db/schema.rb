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

ActiveRecord::Schema.define(:version => 20130213143800) do

  create_table "accomplishments", :force => true do |t|
    t.integer  "enrollment_id"
    t.integer  "phase_id"
    t.date     "conclusion_date"
    t.string   "obs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "accomplishments", ["enrollment_id"], :name => "accomplishments_enrollment_id_fkey"
  add_index "accomplishments", ["phase_id"], :name => "accomplishments_phase_id_fkey"

  create_table "advisement_authorizations", :force => true do |t|
    t.integer  "professor_id"
    t.integer  "level_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "advisement_authorizations", ["level_id"], :name => "advisement_authorizations_level_id_fkey"
  add_index "advisement_authorizations", ["professor_id"], :name => "advisement_authorizations_professor_id_fkey"

  create_table "advisements", :force => true do |t|
    t.integer  "professor_id",  :null => false
    t.integer  "enrollment_id", :null => false
    t.boolean  "main_advisor"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "advisements", ["enrollment_id"], :name => "index_advisements_on_enrollment_id"
  add_index "advisements", ["professor_id"], :name => "index_advisements_on_professor_id"

  create_table "cities", :force => true do |t|
    t.string   "name"
    t.integer  "state_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cities", ["state_id"], :name => "cities_state_id_fkey"

  create_table "countries", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "courses", :force => true do |t|
    t.string   "name"
    t.integer  "level_id"
    t.integer  "institution_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "courses", ["institution_id"], :name => "courses_institution_id_fkey"
  add_index "courses", ["level_id"], :name => "courses_level_id_fkey"

  create_table "courses_students", :id => false, :force => true do |t|
    t.integer "course_id",  :null => false
    t.integer "student_id", :null => false
  end

  add_index "courses_students", ["course_id"], :name => "index_courses_students_on_course_id"
  add_index "courses_students", ["student_id"], :name => "index_courses_students_on_student_id"

  create_table "deferral_types", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.integer  "duration_semesters"
    t.integer  "phase_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "duration_months",    :default => 0
    t.integer  "duration_days",      :default => 0
  end

  add_index "deferral_types", ["phase_id"], :name => "deferral_types_phase_id_fkey"

  create_table "deferrals", :force => true do |t|
    t.date     "approval_date"
    t.string   "obs"
    t.integer  "enrollment_id"
    t.integer  "deferral_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "deferrals", ["deferral_type_id"], :name => "deferrals_deferral_type_id_fkey"
  add_index "deferrals", ["enrollment_id"], :name => "deferrals_enrollment_id_fkey"

  create_table "dismissal_reasons", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dismissals", :force => true do |t|
    t.date     "date"
    t.integer  "enrollment_id"
    t.integer  "dismissal_reason_id"
    t.text     "obs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "dismissals", ["dismissal_reason_id"], :name => "dismissals_dismissal_reason_id_fkey"
  add_index "dismissals", ["enrollment_id"], :name => "dismissals_enrollment_id_fkey"

  create_table "enrollment_statuses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "enrollments", :force => true do |t|
    t.string   "enrollment_number"
    t.integer  "student_id"
    t.integer  "level_id"
    t.integer  "enrollment_status_id"
    t.date     "admission_date"
    t.text     "obs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "enrollments", ["enrollment_status_id"], :name => "enrollments_enrollment_status_id_fkey"
  add_index "enrollments", ["level_id"], :name => "enrollments_level_id_fkey"
  add_index "enrollments", ["student_id"], :name => "enrollments_student_id_fkey"

  create_table "institutions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "code"
  end

  create_table "levels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "phase_durations", :force => true do |t|
    t.integer  "phase_id"
    t.integer  "level_id"
    t.integer  "deadline_semesters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "deadline_months",    :default => 0
    t.integer  "deadline_days",      :default => 0
  end

  add_index "phase_durations", ["level_id"], :name => "phase_durations_level_id_fkey"
  add_index "phase_durations", ["phase_id"], :name => "phase_durations_phase_id_fkey"

  create_table "phases", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "professors", :force => true do |t|
    t.string   "name"
    t.string   "cpf"
    t.date     "birthdate"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sex"
    t.string   "civil_status"
    t.string   "identity_number"
    t.string   "identity_issuing_body"
    t.string   "identity_expedition_date"
    t.string   "neighbourhood"
    t.string   "address"
    t.integer  "state_id"
    t.integer  "city_id"
    t.string   "zip_code"
    t.string   "telephone1"
    t.string   "telephone2"
    t.string   "siape"
  end

  add_index "professors", ["city_id"], :name => "professors_city_id_fkey"
  add_index "professors", ["state_id"], :name => "professors_state_id_fkey"

  create_table "scholarship_durations", :force => true do |t|
    t.integer  "scholarship_id", :null => false
    t.integer  "enrollment_id",  :null => false
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.date     "cancel_date"
  end

  add_index "scholarship_durations", ["enrollment_id"], :name => "index_scholarship_durations_on_enrollment_id"
  add_index "scholarship_durations", ["scholarship_id"], :name => "index_scholarship_durations_on_scholarship_id"

  create_table "scholarship_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scholarships", :force => true do |t|
    t.string   "scholarship_number"
    t.integer  "level_id"
    t.integer  "sponsor_id"
    t.integer  "scholarship_type_id"
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "professor_id"
  end

  add_index "scholarships", ["level_id"], :name => "scholarships_level_id_fkey"
  add_index "scholarships", ["professor_id"], :name => "scholarships_professor_id_fkey"
  add_index "scholarships", ["scholarship_type_id"], :name => "scholarships_scholarship_type_id_fkey"
  add_index "scholarships", ["sponsor_id"], :name => "scholarships_sponsor_id_fkey"

  create_table "sponsors", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "states", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "states", ["country_id"], :name => "states_country_id_fkey"

  create_table "students", :force => true do |t|
    t.string   "name"
    t.string   "cpf"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "obs"
    t.date     "birthdate"
    t.string   "sex"
    t.string   "civil_status"
    t.string   "father_name"
    t.string   "mother_name"
    t.integer  "country_id"
    t.integer  "birthplace"
    t.string   "identity_number"
    t.string   "identity_issuing_body"
    t.date     "identity_expedition_date"
    t.string   "employer"
    t.string   "job_position"
    t.integer  "state_id"
    t.integer  "city_id"
    t.string   "neighbourhood"
    t.string   "zip_code"
    t.string   "address"
    t.string   "telephone1"
    t.string   "telephone2"
    t.string   "email"
  end

  add_index "students", ["city_id"], :name => "students_city_id_fkey"
  add_index "students", ["country_id"], :name => "students_country_id_fkey"
  add_index "students", ["state_id"], :name => "students_state_id_fkey"

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "hashed_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_foreign_key "accomplishments", ["enrollment_id"], "enrollments", ["id"], :name => "accomplishments_enrollment_id_fkey"
  add_foreign_key "accomplishments", ["phase_id"], "phases", ["id"], :name => "accomplishments_phase_id_fkey"

  add_foreign_key "advisement_authorizations", ["level_id"], "levels", ["id"], :name => "advisement_authorizations_level_id_fkey"
  add_foreign_key "advisement_authorizations", ["professor_id"], "professors", ["id"], :name => "advisement_authorizations_professor_id_fkey"

  add_foreign_key "advisements", ["enrollment_id"], "enrollments", ["id"], :name => "advisements_enrollment_id_fkey"
  add_foreign_key "advisements", ["professor_id"], "professors", ["id"], :name => "advisements_professor_id_fkey"

  add_foreign_key "cities", ["state_id"], "states", ["id"], :name => "cities_state_id_fkey"

  add_foreign_key "courses", ["institution_id"], "institutions", ["id"], :name => "courses_institution_id_fkey"
  add_foreign_key "courses", ["level_id"], "levels", ["id"], :name => "courses_level_id_fkey"

  add_foreign_key "courses_students", ["course_id"], "courses", ["id"], :name => "courses_students_course_id_fkey"
  add_foreign_key "courses_students", ["student_id"], "students", ["id"], :name => "courses_students_student_id_fkey"

  add_foreign_key "deferral_types", ["phase_id"], "phases", ["id"], :name => "deferral_types_phase_id_fkey"

  add_foreign_key "deferrals", ["deferral_type_id"], "deferral_types", ["id"], :name => "deferrals_deferral_type_id_fkey"
  add_foreign_key "deferrals", ["enrollment_id"], "enrollments", ["id"], :name => "deferrals_enrollment_id_fkey"

  add_foreign_key "dismissals", ["dismissal_reason_id"], "dismissal_reasons", ["id"], :name => "dismissals_dismissal_reason_id_fkey"
  add_foreign_key "dismissals", ["enrollment_id"], "enrollments", ["id"], :name => "dismissals_enrollment_id_fkey"

  add_foreign_key "enrollments", ["enrollment_status_id"], "enrollment_statuses", ["id"], :name => "enrollments_enrollment_status_id_fkey"
  add_foreign_key "enrollments", ["level_id"], "levels", ["id"], :name => "enrollments_level_id_fkey"
  add_foreign_key "enrollments", ["student_id"], "students", ["id"], :name => "enrollments_student_id_fkey"

  add_foreign_key "phase_durations", ["level_id"], "levels", ["id"], :name => "phase_durations_level_id_fkey"
  add_foreign_key "phase_durations", ["phase_id"], "phases", ["id"], :name => "phase_durations_phase_id_fkey"

  add_foreign_key "professors", ["city_id"], "cities", ["id"], :name => "professors_city_id_fkey"
  add_foreign_key "professors", ["state_id"], "states", ["id"], :name => "professors_state_id_fkey"

  add_foreign_key "scholarship_durations", ["enrollment_id"], "enrollments", ["id"], :name => "scholarship_durations_enrollment_id_fkey"
  add_foreign_key "scholarship_durations", ["scholarship_id"], "scholarships", ["id"], :name => "scholarship_durations_scholarship_id_fkey"

  add_foreign_key "scholarships", ["level_id"], "levels", ["id"], :name => "scholarships_level_id_fkey"
  add_foreign_key "scholarships", ["professor_id"], "professors", ["id"], :name => "scholarships_professor_id_fkey"
  add_foreign_key "scholarships", ["scholarship_type_id"], "scholarship_types", ["id"], :name => "scholarships_scholarship_type_id_fkey"
  add_foreign_key "scholarships", ["sponsor_id"], "sponsors", ["id"], :name => "scholarships_sponsor_id_fkey"

  add_foreign_key "states", ["country_id"], "countries", ["id"], :name => "states_country_id_fkey"

  add_foreign_key "students", ["city_id"], "cities", ["id"], :name => "students_city_id_fkey"
  add_foreign_key "students", ["country_id"], "countries", ["id"], :name => "students_country_id_fkey"
  add_foreign_key "students", ["state_id"], "states", ["id"], :name => "students_state_id_fkey"

end
