class RemoveAllForeignKeys < ActiveRecord::Migration
  def up
    create_table "states_temp", :force => true do |t|
      t.string   "name"
      t.string   "code"
      t.integer  "country_id", foreign_key: false
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end
    execute "INSERT INTO states_temp(id,name,code,country_id,created_at,updated_at) 
      SELECT id,name,code,country_id,created_at,updated_at FROM states"

    create_table "cities_temp", :force => true do |t|
      t.string   "name"
      t.integer  "state_id", foreign_key: false
      t.datetime "created_at", :null => false
      t.datetime "updated_at", :null => false
    end
    execute "INSERT INTO cities_temp(id,name,state_id,created_at,updated_at)
     SELECT id,name,state_id,created_at,updated_at FROM cities"

    create_table "students_temp", :force => true do |t|
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
      t.integer  "country_id", foreign_key: false
      t.integer  "birthplace"
      t.string   "identity_number"
      t.string   "identity_issuing_body"
      t.date     "identity_expedition_date"
      t.string   "employer"
      t.string   "job_position"
      t.integer  "state_id", foreign_key: false
      t.integer  "city_id", foreign_key: false
      t.string   "neighbourhood"
      t.string   "zip_code"
      t.string   "address"
      t.string   "telephone1"
      t.string   "telephone2"
      t.string   "email"
    end
    execute "INSERT INTO students_temp(id,name,cpf,created_at,updated_at,obs,birthdate,sex,civil_status,father_name,mother_name,country_id,birthplace,identity_number,identity_issuing_body,identity_expedition_date,employer,job_position,state_id,city_id,neighbourhood,zip_code,address,telephone1,telephone2,email
) 
      SELECT id,name,cpf,created_at,updated_at,obs,birthdate,sex,civil_status,father_name,mother_name,country_id,birthplace,identity_number,identity_issuing_body,identity_expedition_date,employer,job_position,state_id,city_id,neighbourhood,zip_code,address,telephone1,telephone2,email
 FROM students"

    create_table "enrollments_temp", :force => true do |t|
      t.string   "enrollment_number"
      t.integer  "student_id", foreign_key: false
      t.integer  "level_id", foreign_key: false
      t.integer  "enrollment_status_id", foreign_key: false
      t.date     "admission_date"
      t.text     "obs"
      t.datetime "created_at",           :null => false
      t.datetime "updated_at",           :null => false
      t.string   "thesis_title"
    end
    execute "INSERT INTO enrollments_temp(id,enrollment_number,student_id,level_id,enrollment_status_id,admission_date,obs,created_at,updated_at,thesis_title)
      SELECT id,enrollment_number,student_id,level_id,enrollment_status_id,admission_date,obs,created_at,updated_at,thesis_title FROM enrollments"

    create_table "accomplishments_temp", :force => true do |t|
      t.integer  "enrollment_id", foreign_key: false
      t.integer  "phase_id", foreign_key: false
      t.date     "conclusion_date"
      t.string   "obs"
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
    end
    execute "INSERT INTO accomplishments_temp(id,enrollment_id,phase_id,conclusion_date,obs,created_at,updated_at)
      SELECT id,enrollment_id,phase_id,conclusion_date,obs,created_at,updated_at FROM accomplishments"
  
    create_table "professors_temp", :force => true do |t|
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
      t.integer  "state_id", foreign_key: false
      t.integer  "city_id", foreign_key: false
      t.string   "zip_code"
      t.string   "telephone1"
      t.string   "telephone2"
      t.string   "siape"
      t.string   "enrollment_number"
    end
    execute "INSERT INTO professors_temp(id,name,cpf,birthdate,created_at,updated_at,sex,civil_status,identity_number,identity_issuing_body,identity_expedition_date,neighbourhood,address,state_id,city_id,zip_code,telephone1,telephone2,siape,enrollment_number)
      SELECT id,name,cpf,birthdate,created_at,updated_at,sex,civil_status,identity_number,identity_issuing_body,identity_expedition_date,neighbourhood,address,state_id,city_id,zip_code,telephone1,telephone2,siape,enrollment_number FROM professors"
  
    create_table "advisement_authorizations_temp", :force => true do |t|
      t.integer  "professor_id", foreign_key: false
      t.integer  "level_id", foreign_key: false
      t.datetime "created_at",   :null => false
      t.datetime "updated_at",   :null => false
    end
    execute "INSERT INTO advisement_authorizations_temp(id,professor_id,level_id,created_at,updated_at)
      SELECT id,professor_id,level_id,created_at,updated_at FROM advisement_authorizations"
  
    create_table "advisements_temp", :force => true do |t|
      t.integer  "professor_id", foreign_key: false,  :null => false
      t.integer  "enrollment_id", foreign_key: false, :null => false
      t.boolean  "main_advisor"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
    end
    execute "INSERT INTO advisements_temp(id,professor_id,enrollment_id,main_advisor,created_at,updated_at) 
      SELECT id,professor_id,enrollment_id,main_advisor,created_at,updated_at FROM advisements"
  
    create_table "courses_temp", :force => true do |t|
      t.string   "name"
      t.string   "code"
      t.text     "content"
      t.integer  "credits"
      t.integer  "research_area_id", foreign_key: false
      t.integer  "course_type_id", foreign_key: false
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end
    execute "INSERT INTO courses_temp(id,name,code,content,credits,research_area_id,course_type_id,created_at,updated_at)
      SELECT id,name,code,content,credits,research_area_id,course_type_id,created_at,updated_at FROM courses"
  
    create_table "course_classes_temp", :force => true do |t|
      t.string   "name"
      t.integer  "course_id", foreign_key: false
      t.integer  "professor_id", foreign_key: false
      t.integer  "year"
      t.integer  "semester"
      t.datetime "created_at",   :null => false
      t.datetime "updated_at",   :null => false
    end
    execute "INSERT INTO course_classes_temp(id,name,course_id,professor_id,year,semester,created_at,updated_at) 
      SELECT id,name,course_id,professor_id,year,semester,created_at,updated_at FROM course_classes"
  
    create_table "allocations_temp", :force => true do |t|
      t.string   "day"
      t.string   "room"
      t.integer  "start_time"
      t.integer  "end_time"
      t.integer  "course_class_id", foreign_key: false
      t.datetime "created_at",      :null => false
      t.datetime "updated_at",      :null => false
    end
    execute "INSERT INTO allocations_temp(id,day,room,start_time,end_time,course_class_id,created_at,updated_at)
      SELECT id,day,room,start_time,end_time,course_class_id,created_at,updated_at FROM allocations"
    
    create_table "class_enrollments_temp", :force => true do |t|
      t.text     "obs"
      t.integer  "grade"
      t.string   "situation"
      t.integer  "course_class_id", foreign_key: false
      t.integer  "enrollment_id", foreign_key: false
      t.datetime "created_at",                                :null => false
      t.datetime "updated_at",                                :null => false
      t.boolean  "disapproved_by_absence", :default => false
    end
    execute "INSERT INTO class_enrollments_temp(id,obs,grade,situation,course_class_id,enrollment_id,created_at,updated_at,disapproved_by_absence
) 
      SELECT id,obs,grade,situation,course_class_id,enrollment_id,created_at,updated_at,disapproved_by_absence
 FROM class_enrollments"
    
    create_table "deferral_types_temp", :force => true do |t|
      t.string   "name"
      t.string   "description"
      t.integer  "duration_semesters", :default => 0
      t.integer  "phase_id", foreign_key: false
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
      t.integer  "duration_months",    :default => 0
      t.integer  "duration_days",      :default => 0
    end
    execute "INSERT INTO deferral_types_temp(id,name,description,duration_semesters,phase_id,created_at,updated_at,duration_months,duration_days)
      SELECT id,name,description,duration_semesters,phase_id,created_at,updated_at,duration_months,duration_days FROM deferral_types"
    
    create_table "deferrals_temp", :force => true do |t|
      t.date     "approval_date"
      t.string   "obs"
      t.integer  "enrollment_id", foreign_key: false
      t.integer  "deferral_type_id", foreign_key: false
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end
    execute "INSERT INTO deferrals_temp(id,approval_date,obs,enrollment_id,deferral_type_id,created_at,updated_at) 
      SELECT id,approval_date,obs,enrollment_id,deferral_type_id,created_at,updated_at FROM deferrals"
    
    create_table "dismissals_temp", :force => true do |t|
      t.date     "date"
      t.integer  "enrollment_id", foreign_key: false
      t.integer  "dismissal_reason_id", foreign_key: false
      t.text     "obs"
      t.datetime "created_at",          :null => false
      t.datetime "updated_at",          :null => false
    end
    execute "INSERT INTO dismissals_temp(id,date,enrollment_id,dismissal_reason_id,obs,created_at,updated_at)
      SELECT id,date,enrollment_id,dismissal_reason_id,obs,created_at,updated_at FROM dismissals"
    
    create_table "majors_temp", :force => true do |t|
      t.string   "name"
      t.integer  "level_id", foreign_key: false
      t.integer  "institution_id", foreign_key: false
      t.datetime "created_at",     :null => false
      t.datetime "updated_at",     :null => false
    end
    execute "INSERT INTO majors_temp(id,name,level_id,institution_id,created_at,updated_at)
      SELECT id,name,level_id,institution_id,created_at,updated_at FROM majors"
    
    create_table "phase_durations_temp", :force => true do |t|
      t.integer  "phase_id", foreign_key: false
      t.integer  "level_id", foreign_key: false
      t.integer  "deadline_semesters", :default => 0
      t.datetime "created_at",                        :null => false
      t.datetime "updated_at",                        :null => false
      t.integer  "deadline_months",    :default => 0
      t.integer  "deadline_days",      :default => 0
    end
    execute "INSERT INTO phase_durations_temp(id,phase_id,level_id,deadline_semesters,created_at,updated_at,deadline_months,deadline_days)
      SELECT id,phase_id,level_id,deadline_semesters,created_at,updated_at,deadline_months,deadline_days FROM phase_durations"
    
    create_table "professor_research_areas_temp", :force => true do |t|
      t.integer  "professor_id", foreign_key: false
      t.integer  "research_area_id", foreign_key: false
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end
    execute "INSERT INTO professor_research_areas_temp(id,professor_id,research_area_id,created_at,updated_at)
      SELECT id,professor_id,research_area_id,created_at,updated_at FROM professor_research_areas"
    
    create_table "scholarships_temp", :force => true do |t|
      t.string   "scholarship_number"
      t.integer  "level_id", foreign_key: false
      t.integer  "sponsor_id", foreign_key: false
      t.integer  "scholarship_type_id", foreign_key: false
      t.date     "start_date"
      t.date     "end_date"
      t.text     "obs"
      t.datetime "created_at",          :null => false
      t.datetime "updated_at",          :null => false
      t.integer  "professor_id", foreign_key: false
    end
    execute "INSERT INTO scholarships_temp(id,scholarship_number,level_id,sponsor_id,scholarship_type_id,start_date,end_date,obs,created_at,updated_at,professor_id)
      SELECT id,scholarship_number,level_id,sponsor_id,scholarship_type_id,start_date,end_date,obs,created_at,updated_at,professor_id FROM scholarships"
    
    create_table "scholarship_durations_temp", :force => true do |t|
      t.integer  "scholarship_id", foreign_key: false, :null => false
      t.integer  "enrollment_id", foreign_key: false,  :null => false
      t.date     "start_date"
      t.date     "end_date"
      t.text     "obs"
      t.datetime "created_at",     :null => false
      t.datetime "updated_at",     :null => false
      t.date     "cancel_date"
    end
    execute "INSERT INTO scholarship_durations_temp(id,scholarship_id,enrollment_id,start_date,end_date,obs,created_at,updated_at,cancel_date)
      SELECT id,scholarship_id,enrollment_id,start_date,end_date,obs,created_at,updated_at,cancel_date FROM scholarship_durations"
    
    create_table "student_majors_temp", :force => true do |t|
      t.integer "major_id", foreign_key: false,   :null => false
      t.integer "student_id", foreign_key: false, :null => false
    end
    execute "INSERT INTO student_majors_temp(major_id,student_id,id)
      SELECT major_id,student_id,id FROM student_majors"
    
    create_table "users_temp", :force => true do |t|
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
      t.integer  "role_id", foreign_key: false,                :default => 1,  :null => false
    end
    execute "INSERT INTO users_temp(id,name,hashed_password,salt,created_at,updated_at,email,encrypted_password,reset_password_token,reset_password_sent_at,remember_created_at,sign_in_count,current_sign_in_at,last_sign_in_at,current_sign_in_ip,last_sign_in_ip,confirmation_token,confirmed_at,confirmation_sent_at,failed_attempts,unlock_token,locked_at,role_id)
      SELECT id,name,hashed_password,salt,created_at,updated_at,email,encrypted_password,reset_password_token,reset_password_sent_at,remember_created_at,sign_in_count,current_sign_in_at,last_sign_in_at,current_sign_in_ip,last_sign_in_ip,confirmation_token,confirmed_at,confirmation_sent_at,failed_attempts,unlock_token,locked_at,role_id FROM users"
    
    drop_table :users
    rename_table :users_temp, :users

    drop_table :student_majors
    rename_table :student_majors_temp, :student_majors

    drop_table :scholarship_durations
    rename_table :scholarship_durations_temp, :scholarship_durations

    drop_table :scholarships
    rename_table :scholarships_temp, :scholarships

    drop_table :professor_research_areas
    rename_table :professor_research_areas_temp, :professor_research_areas

    drop_table :phase_durations
    rename_table :phase_durations_temp, :phase_durations

    drop_table :majors
    rename_table :majors_temp, :majors

    drop_table :dismissals
    rename_table :dismissals_temp, :dismissals

    drop_table :deferrals
    rename_table :deferrals_temp, :deferrals

    drop_table :deferral_types
    rename_table :deferral_types_temp, :deferral_types

    drop_table :class_enrollments
    rename_table :class_enrollments_temp, :class_enrollments

    drop_table :allocations
    rename_table :allocations_temp, :allocations

    drop_table :course_classes
    rename_table :course_classes_temp, :course_classes

    drop_table :courses
    rename_table :courses_temp, :courses

    drop_table :advisements
    rename_table :advisements_temp, :advisements
    
    drop_table :advisement_authorizations
    rename_table :advisement_authorizations_temp, :advisement_authorizations

    drop_table :professors
    rename_table :professors_temp, :professors

    drop_table :accomplishments
    rename_table :accomplishments_temp, :accomplishments

    drop_table :enrollments
    rename_table :enrollments_temp, :enrollments

    drop_table :students
    rename_table :students_temp, :students

    drop_table :cities
    rename_table :cities_temp, :cities

    drop_table :states
    rename_table :states_temp, :states

    add_index :states, :country_id
    add_index :cities, :state_id
    add_index :students, :city_id
    add_index :students, :state_id
    add_index :students, :country_id
    add_index :enrollments, :enrollment_status_id
    add_index :enrollments, :level_id
    add_index :enrollments, :student_id
    add_index :accomplishments, :phase_id
    add_index :accomplishments, :enrollment_id
    add_index :professors, :city_id
    add_index :professors, :state_id
    add_index :advisement_authorizations, :level_id
    add_index :advisement_authorizations, :professor_id
    add_index :advisements, :enrollment_id
    add_index :advisements, :professor_id
    add_index :courses, :course_type_id
    add_index :courses, :research_area_id
    add_index :course_classes, :course_id
    add_index :course_classes, :professor_id
    add_index :allocations, :course_class_id
    add_index :class_enrollments, :course_class_id
    add_index :class_enrollments, :enrollment_id
    add_index :deferral_types, :phase_id
    add_index :deferrals, :deferral_type_id
    add_index :deferrals, :enrollment_id
    add_index :dismissals, :dismissal_reason_id
    add_index :dismissals, :enrollment_id
    add_index :majors, :institution_id
    add_index :majors, :level_id
    add_index :phase_durations, :phase_id
    add_index :phase_durations, :level_id
    add_index :professor_research_areas, :research_area_id
    add_index :professor_research_areas, :professor_id
    add_index :scholarships, :scholarship_type_id
    add_index :scholarships, :professor_id
    add_index :scholarships, :sponsor_id
    add_index :scholarships, :level_id
    add_index :scholarship_durations, :scholarship_id
    add_index :scholarship_durations, :enrollment_id
    add_index :student_majors, :major_id
    add_index :student_majors, :student_id
    add_index :users, :role_id
  end

  def down
  end
end
