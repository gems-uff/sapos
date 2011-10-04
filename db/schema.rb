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

ActiveRecord::Schema.define(:version => 20111004011410) do

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

  create_table "courses_students", :id => false, :force => true do |t|
    t.integer "course_id",  :null => false
    t.integer "student_id", :null => false
  end

  add_index "courses_students", ["course_id"], :name => "index_courses_students_on_course_id"
  add_index "courses_students", ["student_id"], :name => "index_courses_students_on_student_id"

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

  create_table "professors", :force => true do |t|
    t.string   "name"
    t.string   "cpf"
    t.date     "birthdate"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "scholarship_durations", :force => true do |t|
    t.integer  "scholarship_id", :null => false
    t.integer  "enrollment_id",  :null => false
    t.date     "start_date"
    t.date     "end_date"
    t.text     "obs"
    t.datetime "created_at"
    t.datetime "updated_at"
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

  create_table "users", :force => true do |t|
    t.string   "name"
    t.string   "hashed_password"
    t.string   "salt"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
