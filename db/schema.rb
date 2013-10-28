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

ActiveRecord::Schema.define(:version => 20131015031345) do

  create_table "enrollment_statuses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "levels", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "countries", :force => true do |t|
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
    t.index ["country_id"], :name => "fk__states_country_id"
    t.foreign_key ["country_id"], "countries", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_states_country_id"
  end

  create_table "cities", :force => true do |t|
    t.string   "name"
    t.integer  "state_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.index ["state_id"], :name => "fk__cities_state_id"
    t.foreign_key ["state_id"], "states", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_cities_state_id"
  end

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
    t.index ["city_id"], :name => "fk__students_city_id"
    t.index ["state_id"], :name => "fk__students_state_id"
    t.index ["birthplace"], :name => "fk__students_birthplace"
    t.index ["country_id"], :name => "fk__students_country_id"
    t.foreign_key ["birthplace"], "states", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_students_birthplace"
    t.foreign_key ["city_id"], "cities", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_students_city_id"
    t.foreign_key ["country_id"], "countries", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_students_country_id"
    t.foreign_key ["state_id"], "states", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_students_state_id"
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
    t.index ["enrollment_status_id"], :name => "fk__enrollments_enrollment_status_id"
    t.index ["level_id"], :name => "fk__enrollments_level_id"
    t.index ["student_id"], :name => "fk__enrollments_student_id"
    t.foreign_key ["enrollment_status_id"], "enrollment_statuses", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_enrollments_enrollment_status_id"
    t.foreign_key ["level_id"], "levels", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_enrollments_level_id"
    t.foreign_key ["student_id"], "students", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_enrollments_student_id"
  end

  create_table "phases", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "accomplishments", :force => true do |t|
    t.integer  "enrollment_id"
    t.integer  "phase_id"
    t.date     "conclusion_date"
    t.string   "obs"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.index ["phase_id"], :name => "fk__accomplishments_phase_id"
    t.index ["enrollment_id"], :name => "fk__accomplishments_enrollment_id"
    t.foreign_key ["enrollment_id"], "enrollments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_accomplishments_enrollment_id"
    t.foreign_key ["phase_id"], "phases", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_accomplishments_phase_id"
  end

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
    t.string   "neighbourhood"
    t.string   "address"
    t.integer  "state_id"
    t.integer  "city_id"
    t.string   "zip_code"
    t.string   "telephone1"
    t.string   "telephone2"
    t.string   "siape"
    t.string   "enrollment_number"
    t.index ["city_id"], :name => "fk__professors_city_id"
    t.index ["state_id"], :name => "fk__professors_state_id"
    t.foreign_key ["city_id"], "cities", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_professors_city_id"
    t.foreign_key ["state_id"], "states", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_professors_state_id"
  end

  create_table "advisement_authorizations", :force => true do |t|
    t.integer  "professor_id"
    t.integer  "level_id"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.index ["level_id"], :name => "fk__advisement_authorizations_level_id"
    t.index ["professor_id"], :name => "fk__advisement_authorizations_professor_id"
    t.foreign_key ["level_id"], "levels", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_advisement_authorizations_level_id"
    t.foreign_key ["professor_id"], "professors", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_advisement_authorizations_professor_id"
  end

  create_table "advisements", :force => true do |t|
    t.integer  "professor_id",  :null => false
    t.integer  "enrollment_id", :null => false
    t.boolean  "main_advisor"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.index ["enrollment_id"], :name => "index_advisements_on_enrollment_id"
    t.index ["professor_id"], :name => "index_advisements_on_professor_id"
    t.index ["enrollment_id"], :name => "fk__advisements_enrollment_id"
    t.index ["professor_id"], :name => "fk__advisements_professor_id"
    t.foreign_key ["enrollment_id"], "enrollments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_advisements_enrollment_id"
    t.foreign_key ["professor_id"], "professors", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_advisements_professor_id"
  end

  create_table "course_types", :force => true do |t|
    t.string   "name"
    t.boolean  "has_score"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "research_areas", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
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
    t.index ["course_type_id"], :name => "fk__courses_course_type_id"
    t.index ["research_area_id"], :name => "fk__courses_research_area_id"
    t.foreign_key ["course_type_id"], "course_types", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_courses_course_type_id"
    t.foreign_key ["research_area_id"], "research_areas", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_courses_research_area_id"
  end

  create_table "course_classes", :force => true do |t|
    t.string   "name"
    t.integer  "course_id"
    t.integer  "professor_id"
    t.integer  "year"
    t.integer  "semester"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.index ["professor_id"], :name => "fk__course_classes_professor_id"
    t.index ["course_id"], :name => "fk__course_classes_course_id"
    t.foreign_key ["course_id"], "courses", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_course_classes_course_id"
    t.foreign_key ["professor_id"], "professors", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_course_classes_professor_id"
  end

  create_table "allocations", :force => true do |t|
    t.string   "day"
    t.string   "room"
    t.integer  "start_time"
    t.integer  "end_time"
    t.integer  "course_class_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.index ["course_class_id"], :name => "fk__allocations_course_class_id"
    t.foreign_key ["course_class_id"], "course_classes", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_allocations_course_class_id"
  end

  create_table "class_enrollments", :force => true do |t|
    t.text     "obs"
    t.integer  "grade"
    t.string   "situation"
    t.integer  "course_class_id"
    t.integer  "enrollment_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "disapproved_by_absence", :default => false
    t.index ["enrollment_id"], :name => "fk__class_enrollments_enrollment_id"
    t.index ["course_class_id"], :name => "fk__class_enrollments_course_class_id"
    t.foreign_key ["course_class_id"], "course_classes", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_class_enrollments_course_class_id"
    t.foreign_key ["enrollment_id"], "enrollments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_class_enrollments_enrollment_id"
  end

  create_table "configurations", :force => true do |t|
    t.string   "name"
    t.string   "variable"
    t.string   "value"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "courses_students", :id => false, :force => true do |t|
    t.integer "course_id",  :null => false
    t.integer "student_id", :null => false
    t.index ["student_id"], :name => "index_courses_students_on_student_id"
    t.index ["course_id"], :name => "index_courses_students_on_course_id"
    t.index ["student_id"], :name => "fk__courses_students_student_id"
    t.index ["course_id"], :name => "fk__courses_students_course_id"
    t.foreign_key ["course_id"], "courses", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_courses_students_course_id"
    t.foreign_key ["student_id"], "students", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_courses_students_student_id"
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
    t.index ["phase_id"], :name => "fk__deferral_types_phase_id"
    t.foreign_key ["phase_id"], "phases", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_deferral_types_phase_id"
  end

  create_table "deferrals", :force => true do |t|
    t.date     "approval_date"
    t.string   "obs"
    t.integer  "enrollment_id"
    t.integer  "deferral_type_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.index ["deferral_type_id"], :name => "fk__deferrals_deferral_type_id"
    t.index ["enrollment_id"], :name => "fk__deferrals_enrollment_id"
    t.foreign_key ["deferral_type_id"], "deferral_types", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_deferrals_deferral_type_id"
    t.foreign_key ["enrollment_id"], "enrollments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_deferrals_enrollment_id"
  end

  create_table "dismissal_reasons", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "show_advisor_name", :default => false
  end

  create_table "dismissals", :force => true do |t|
    t.date     "date"
    t.integer  "enrollment_id"
    t.integer  "dismissal_reason_id"
    t.text     "obs"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
    t.index ["dismissal_reason_id"], :name => "fk__dismissals_dismissal_reason_id"
    t.index ["enrollment_id"], :name => "fk__dismissals_enrollment_id"
    t.foreign_key ["dismissal_reason_id"], "dismissal_reasons", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_dismissals_dismissal_reason_id"
    t.foreign_key ["enrollment_id"], "enrollments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_dismissals_enrollment_id"
  end

  create_table "institutions", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "code"
  end

  create_table "majors", :force => true do |t|
    t.string   "name"
    t.integer  "level_id"
    t.integer  "institution_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.index ["institution_id"], :name => "fk__majors_institution_id"
    t.index ["level_id"], :name => "fk__majors_level_id"
    t.foreign_key ["institution_id"], "institutions", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_majors_institution_id"
    t.foreign_key ["level_id"], "levels", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_majors_level_id"
  end

  create_table "phase_durations", :force => true do |t|
    t.integer  "phase_id"
    t.integer  "level_id"
    t.integer  "deadline_semesters", :default => 0
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.integer  "deadline_months",    :default => 0
    t.integer  "deadline_days",      :default => 0
    t.index ["level_id"], :name => "fk__phase_durations_level_id"
    t.index ["phase_id"], :name => "fk__phase_durations_phase_id"
    t.foreign_key ["level_id"], "levels", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_phase_durations_level_id"
    t.foreign_key ["phase_id"], "phases", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_phase_durations_phase_id"
  end

  create_table "professor_research_areas", :force => true do |t|
    t.integer  "professor_id"
    t.integer  "research_area_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.index ["research_area_id"], :name => "fk__professor_research_areas_research_area_id"
    t.index ["professor_id"], :name => "fk__professor_research_areas_professor_id"
    t.foreign_key ["professor_id"], "professors", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_professor_research_areas_professor_id"
    t.foreign_key ["research_area_id"], "research_areas", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_professor_research_areas_research_area_id"
  end

  create_table "roles", :force => true do |t|
    t.string   "name",        :limit => 50, :null => false
    t.string   "description",               :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "scholarship_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sponsors", :force => true do |t|
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
    t.index ["professor_id"], :name => "fk__scholarships_professor_id"
    t.index ["scholarship_type_id"], :name => "fk__scholarships_scholarship_type_id"
    t.index ["sponsor_id"], :name => "fk__scholarships_sponsor_id"
    t.index ["level_id"], :name => "fk__scholarships_level_id"
    t.foreign_key ["level_id"], "levels", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_scholarships_level_id"
    t.foreign_key ["professor_id"], "professors", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_scholarships_professor_id"
    t.foreign_key ["scholarship_type_id"], "scholarship_types", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_scholarships_scholarship_type_id"
    t.foreign_key ["sponsor_id"], "sponsors", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_scholarships_sponsor_id"
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
    t.index ["enrollment_id"], :name => "index_scholarship_durations_on_enrollment_id"
    t.index ["scholarship_id"], :name => "index_scholarship_durations_on_scholarship_id"
    t.index ["enrollment_id"], :name => "fk__scholarship_durations_enrollment_id"
    t.index ["scholarship_id"], :name => "fk__scholarship_durations_scholarship_id"
    t.foreign_key ["enrollment_id"], "enrollments", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_scholarship_durations_enrollment_id"
    t.foreign_key ["scholarship_id"], "scholarships", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_scholarship_durations_scholarship_id"
  end

  create_table "student_majors", :force => true do |t|
    t.integer "major_id",   :null => false
    t.integer "student_id", :null => false
    t.index ["major_id"], :name => "ltered_student_majors_major_id"
    t.index ["student_id"], :name => "ltered_student_majors_student_id"
    t.index ["student_id"], :name => "index_student_majors_on_student_id"
    t.index ["major_id"], :name => "fk__majors_students_course_id"
    t.index ["major_id"], :name => "index_majors_students_on_course_id"
    t.index ["student_id"], :name => "fk__student_majors_student_id"
    t.index ["major_id"], :name => "fk__student_majors_major_id"
    t.foreign_key ["major_id"], "majors", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_student_majors_major_id"
    t.foreign_key ["student_id"], "students", ["id"], :on_update => :no_action, :on_delete => :no_action, :name => "fk_student_majors_student_id"
  end

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
    t.index ["role_id"], :name => "fk__users_role_id"
    t.foreign_key ["role_id"], "roles", ["id"], :on_update => :restrict, :on_delete => :restrict, :name => "fk_users_role_id"
  end

  create_table "versions", :force => true do |t|
    t.string   "item_type",  :null => false
    t.integer  "item_id",    :null => false
    t.string   "event",      :null => false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"
  end

end
