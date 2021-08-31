class MigrateIdsToBigint < ActiveRecord::Migration[6.0]
  def up
    remove_index :versions, name: "index_versions_on_item_type_and_item_id" if index_exists?(:versions, name: "index_versions_on_item_type_and_item_id")
    
    add_column :students, :temp_user_id, :integer, limit: 8
    Student.update_all("temp_user_id = user_id")
    remove_reference :students, :user

    # accomplishments
    change_column :accomplishments, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # advisement_authorizations
    change_column :advisement_authorizations, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # advisements
    change_column :advisements, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # allocations
    change_column :allocations, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # carrier_wave_files
    change_column :carrier_wave_files, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # cities
    remove_index :professors, name: "index_professors_on_city_id" if index_exists?(:professors, name: "index_professors_on_city_id")
    remove_index :students, name: "index_students_on_birth_city_id" if index_exists?(:students, name: "index_students_on_birth_city_id")
    remove_index :students, name: "index_students_on_city_id" if index_exists?(:students, name: "index_students_on_city_id")
    change_column :cities, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :professors, :city_id, :integer, limit: 8
    add_index :professors, :city_id unless index_exists?(:professors, :city_id)
    change_column :students, :birth_city_id, :integer, limit: 8
    add_index :students, :birth_city_id unless index_exists?(:students, :birth_city_id)
    change_column :students, :city_id, :integer, limit: 8
    add_index :students, :city_id unless index_exists?(:students, :city_id)

    # class_enrollments
    change_column :class_enrollments, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # countries
    remove_index :professors, name: "index_professors_on_academic_title_country_id" if index_exists?(:professors, name: "index_professors_on_academic_title_country_id")
    remove_index :states, name: "index_states_on_country_id" if index_exists?(:states, name: "index_states_on_country_id")
    remove_index :students, name: "index_students_on_birth_country_id" if index_exists?(:students, name: "index_students_on_birth_country_id")
    change_column :countries, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :professors, :academic_title_country_id, :integer, limit: 8
    add_index :professors, :academic_title_country_id unless index_exists?(:professors, :academic_title_country_id)
    change_column :states, :country_id, :integer, limit: 8
    add_index :states, :country_id unless index_exists?(:states, :country_id)
    change_column :students, :birth_country_id, :integer, limit: 8
    add_index :students, :birth_country_id unless index_exists?(:students, :birth_country_id)

    # course_classes
    remove_index :allocations, name: "index_allocations_on_course_class_id" if index_exists?(:allocations, name: "index_allocations_on_course_class_id")
    remove_index :class_enrollments, name: "index_class_enrollments_on_course_class_id" if index_exists?(:class_enrollments, name: "index_class_enrollments_on_course_class_id")
    change_column :course_classes, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :allocations, :course_class_id, :integer, limit: 8
    add_index :allocations, :course_class_id unless index_exists?(:allocations, :course_class_id)
    change_column :class_enrollments, :course_class_id, :integer, limit: 8
    add_index :class_enrollments, :course_class_id unless index_exists?(:class_enrollments, :course_class_id)

    # course_research_areas
    change_column :course_research_areas, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # course_types
    remove_index :courses, name: "index_courses_on_course_type_id" if index_exists?(:courses, name: "index_courses_on_course_type_id")
    change_column :course_types, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :courses, :course_type_id, :integer, limit: 8
    add_index :courses, :course_type_id unless index_exists?(:courses, :course_type_id)

    # courses
    remove_index :course_classes, name: "index_course_classes_on_course_id" if index_exists?(:course_classes, name: "index_course_classes_on_course_id")
    change_column :courses, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :course_classes, :course_id, :integer, limit: 8
    add_index :course_classes, :course_id unless index_exists?(:course_classes, :course_id)

    # custom_variables
    change_column :custom_variables, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # deferral_types
    remove_index :deferrals, name: "index_deferrals_on_deferral_type_id" if index_exists?(:deferrals, name: "index_deferrals_on_deferral_type_id")
    change_column :deferral_types, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :deferrals, :deferral_type_id, :integer, limit: 8
    add_index :deferrals, :deferral_type_id unless index_exists?(:deferrals, :deferral_type_id)

    # deferrals
    change_column :deferrals, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # dismissal_reasons
    remove_index :dismissals, name: "index_dismissals_on_dismissal_reason_id" if index_exists?(:dismissals, name: "index_dismissals_on_dismissal_reason_id")
    change_column :dismissal_reasons, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :dismissals, :dismissal_reason_id, :integer, limit: 8
    add_index :dismissals, :dismissal_reason_id unless index_exists?(:dismissals, :dismissal_reason_id)

    # dismissals
    change_column :dismissals, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # email_templates
    change_column :email_templates, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # enrollment_holds
    change_column :enrollment_holds, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # enrollment_statuses
    remove_index :enrollments, name: "index_enrollments_on_enrollment_status_id" if index_exists?(:enrollments, name: "index_enrollments_on_enrollment_status_id")
    change_column :enrollment_statuses, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :enrollments, :enrollment_status_id, :integer, limit: 8
    add_index :enrollments, :enrollment_status_id unless index_exists?(:enrollments, :enrollment_status_id)

    # enrollments
    remove_index :accomplishments, name: "index_accomplishments_on_enrollment_id" if index_exists?(:accomplishments, name: "index_accomplishments_on_enrollment_id")
    remove_index :advisements, name: "index_advisements_on_enrollment_id" if index_exists?(:advisements, name: "index_advisements_on_enrollment_id")
    remove_index :class_enrollments, name: "index_class_enrollments_on_enrollment_id" if index_exists?(:class_enrollments, name: "index_class_enrollments_on_enrollment_id")
    remove_index :deferrals, name: "index_deferrals_on_enrollment_id" if index_exists?(:deferrals, name: "index_deferrals_on_enrollment_id")
    remove_index :dismissals, name: "index_dismissals_on_enrollment_id" if index_exists?(:dismissals, name: "index_dismissals_on_enrollment_id")
    remove_index :enrollment_holds, name: "index_enrollment_holds_on_enrollment_id" if index_exists?(:enrollment_holds, name: "index_enrollment_holds_on_enrollment_id")
    remove_index :scholarship_durations, name: "index_scholarship_durations_on_enrollment_id" if index_exists?(:scholarship_durations, name: "index_scholarship_durations_on_enrollment_id")
    remove_index :thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_enrollment_id" if index_exists?(:thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_enrollment_id")
    change_column :enrollments, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :accomplishments, :enrollment_id, :integer, limit: 8
    add_index :accomplishments, :enrollment_id unless index_exists?(:accomplishments, :enrollment_id)
    change_column :advisements, :enrollment_id, :integer, limit: 8
    add_index :advisements, :enrollment_id unless index_exists?(:advisements, :enrollment_id)
    change_column :class_enrollments, :enrollment_id, :integer, limit: 8
    add_index :class_enrollments, :enrollment_id unless index_exists?(:class_enrollments, :enrollment_id)
    change_column :deferrals, :enrollment_id, :integer, limit: 8
    add_index :deferrals, :enrollment_id unless index_exists?(:deferrals, :enrollment_id)
    change_column :dismissals, :enrollment_id, :integer, limit: 8
    add_index :dismissals, :enrollment_id unless index_exists?(:dismissals, :enrollment_id)
    change_column :enrollment_holds, :enrollment_id, :integer, limit: 8
    add_index :enrollment_holds, :enrollment_id unless index_exists?(:enrollment_holds, :enrollment_id)
    change_column :scholarship_durations, :enrollment_id, :integer, limit: 8
    add_index :scholarship_durations, :enrollment_id unless index_exists?(:scholarship_durations, :enrollment_id)
    change_column :thesis_defense_committee_participations, :enrollment_id, :integer, limit: 8
    add_index :thesis_defense_committee_participations, :enrollment_id unless index_exists?(:thesis_defense_committee_participations, :enrollment_id)

    # institutions
    remove_index :majors, name: "index_majors_on_institution_id" if index_exists?(:majors, name: "index_majors_on_institution_id")
    remove_index :professors, name: "index_professors_on_academic_title_institution_id" if index_exists?(:professors, name: "index_professors_on_academic_title_institution_id")
    remove_index :professors, name: "index_professors_on_institution_id" if index_exists?(:professors, name: "index_professors_on_institution_id")
    change_column :institutions, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :majors, :institution_id, :integer, limit: 8
    add_index :majors, :institution_id unless index_exists?(:majors, :institution_id)
    change_column :professors, :academic_title_institution_id, :integer, limit: 8
    add_index :professors, :academic_title_institution_id unless index_exists?(:professors, :academic_title_institution_id)
    change_column :professors, :institution_id, :integer, limit: 8
    add_index :professors, :institution_id unless index_exists?(:professors, :institution_id)

    # levels
    remove_index :advisement_authorizations, name: "index_advisement_authorizations_on_level_id" if index_exists?(:advisement_authorizations, name: "index_advisement_authorizations_on_level_id")
    remove_index :enrollments, name: "index_enrollments_on_level_id" if index_exists?(:enrollments, name: "index_enrollments_on_level_id")
    remove_index :majors, name: "index_majors_on_level_id" if index_exists?(:majors, name: "index_majors_on_level_id")
    remove_index :phase_durations, name: "index_phase_durations_on_level_id" if index_exists?(:phase_durations, name: "index_phase_durations_on_level_id")
    remove_index :professors, name: "index_professors_on_academic_title_level_id" if index_exists?(:professors, name: "index_professors_on_academic_title_level_id")
    remove_index :scholarships, name: "index_scholarships_on_level_id" if index_exists?(:scholarships, name: "index_scholarships_on_level_id")
    change_column :levels, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :advisement_authorizations, :level_id, :integer, limit: 8
    add_index :advisement_authorizations, :level_id unless index_exists?(:advisement_authorizations, :level_id)
    change_column :enrollments, :level_id, :integer, limit: 8
    add_index :enrollments, :level_id unless index_exists?(:enrollments, :level_id)
    change_column :majors, :level_id, :integer, limit: 8
    add_index :majors, :level_id unless index_exists?(:majors, :level_id)
    change_column :phase_durations, :level_id, :integer, limit: 8
    add_index :phase_durations, :level_id unless index_exists?(:phase_durations, :level_id)
    change_column :professors, :academic_title_level_id, :integer, limit: 8
    add_index :professors, :academic_title_level_id unless index_exists?(:professors, :academic_title_level_id)
    change_column :scholarships, :level_id, :integer, limit: 8
    add_index :scholarships, :level_id unless index_exists?(:scholarships, :level_id)

    # majors
    remove_index :student_majors, name: "index_student_majors_on_major_id" if index_exists?(:student_majors, name: "index_student_majors_on_major_id")
    change_column :majors, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :student_majors, :major_id, :integer, limit: 8
    add_index :student_majors, :major_id unless index_exists?(:student_majors, :major_id)

    # notification_logs
    change_column :notification_logs, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # notification_params
    change_column :notification_params, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # notifications
    remove_index :notification_logs, name: "index_notification_logs_on_notification_id" if index_exists?(:notification_logs, name: "index_notification_logs_on_notification_id")
    remove_index :notification_params, name: "index_notification_params_on_notification_id" if index_exists?(:notification_params, name: "index_notification_params_on_notification_id")
    change_column :notifications, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :notification_logs, :notification_id, :integer, limit: 8
    add_index :notification_logs, :notification_id unless index_exists?(:notification_logs, :notification_id)
    change_column :notification_params, :notification_id, :integer, limit: 8
    add_index :notification_params, :notification_id unless index_exists?(:notification_params, :notification_id)

    # phase_completions
    change_column :phase_completions, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # phase_durations
    change_column :phase_durations, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # phases
    remove_index :accomplishments, name: "index_accomplishments_on_phase_id" if index_exists?(:accomplishments, name: "index_accomplishments_on_phase_id")
    remove_index :deferral_types, name: "index_deferral_types_on_phase_id" if index_exists?(:deferral_types, name: "index_deferral_types_on_phase_id")
    remove_index :phase_durations, name: "index_phase_durations_on_phase_id" if index_exists?(:phase_durations, name: "index_phase_durations_on_phase_id")
    change_column :phases, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :accomplishments, :phase_id, :integer, limit: 8
    add_index :accomplishments, :phase_id unless index_exists?(:accomplishments, :phase_id)
    change_column :deferral_types, :phase_id, :integer, limit: 8
    add_index :deferral_types, :phase_id unless index_exists?(:deferral_types, :phase_id)
    change_column :phase_durations, :phase_id, :integer, limit: 8
    add_index :phase_durations, :phase_id unless index_exists?(:phase_durations, :phase_id)

    # professor_research_areas
    change_column :professor_research_areas, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # professors
    remove_index :advisement_authorizations, name: "index_advisement_authorizations_on_professor_id" if index_exists?(:advisement_authorizations, name: "index_advisement_authorizations_on_professor_id")
    remove_index :advisements, name: "index_advisements_on_professor_id" if index_exists?(:advisements, name: "index_advisements_on_professor_id")
    remove_index :course_classes, name: "index_course_classes_on_professor_id" if index_exists?(:course_classes, name: "index_course_classes_on_professor_id")
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_professor_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_professor_id")
    remove_index :scholarships, name: "index_scholarships_on_professor_id" if index_exists?(:scholarships, name: "index_scholarships_on_professor_id")
    remove_index :thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id" if index_exists?(:thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id")
    change_column :professors, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :advisement_authorizations, :professor_id, :integer, limit: 8
    add_index :advisement_authorizations, :professor_id unless index_exists?(:advisement_authorizations, :professor_id)
    change_column :advisements, :professor_id, :integer, limit: 8
    add_index :advisements, :professor_id unless index_exists?(:advisements, :professor_id)
    change_column :course_classes, :professor_id, :integer, limit: 8
    add_index :course_classes, :professor_id unless index_exists?(:course_classes, :professor_id)
    change_column :professor_research_areas, :professor_id, :integer, limit: 8
    add_index :professor_research_areas, :professor_id unless index_exists?(:professor_research_areas, :professor_id)
    change_column :scholarships, :professor_id, :integer, limit: 8
    add_index :scholarships, :professor_id unless index_exists?(:scholarships, :professor_id)
    change_column :thesis_defense_committee_participations, :professor_id, :integer, limit: 8
    add_index :thesis_defense_committee_participations, :professor_id unless index_exists?(:thesis_defense_committee_participations, :professor_id)

    # queries
    remove_index :query_params, name: "index_query_params_on_query_id" if index_exists?(:query_params, name: "index_query_params_on_query_id")
    change_column :queries, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :query_params, :query_id, :integer, limit: 8
    add_index :query_params, :query_id unless index_exists?(:query_params, :query_id)

    # query_params
    remove_index :notification_params, name: "index_notification_params_on_query_param_id" if index_exists?(:notification_params, name: "index_notification_params_on_query_param_id")
    change_column :query_params, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :notification_params, :query_param_id, :integer, limit: 8
    add_index :notification_params, :query_param_id unless index_exists?(:notification_params, :query_param_id)

    # report_configurations
    change_column :report_configurations, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # research_areas
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_research_area_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_research_area_id")
    change_column :research_areas, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :professor_research_areas, :research_area_id, :integer, limit: 8
    add_index :professor_research_areas, :research_area_id unless index_exists?(:professor_research_areas, :research_area_id)

    # roles
    remove_index :users, name: "index_users_on_role_id" if index_exists?(:users, name: "index_users_on_role_id")
    change_column :roles, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :users, :role_id, :integer, limit: 8
    add_index :users, :role_id unless index_exists?(:users, :role_id)

    # scholarship_durations
    remove_index :scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id" if index_exists?(:scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id")
    change_column :scholarship_durations, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :scholarship_suspensions, :scholarship_duration_id, :integer, limit: 8
    add_index :scholarship_suspensions, :scholarship_duration_id unless index_exists?(:scholarship_suspensions, :scholarship_duration_id)

    # scholarship_suspensions
    change_column :scholarship_suspensions, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # scholarship_types
    remove_index :scholarships, name: "index_scholarships_on_scholarship_type_id" if index_exists?(:scholarships, name: "index_scholarships_on_scholarship_type_id")
    change_column :scholarship_types, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :scholarships, :scholarship_type_id, :integer, limit: 8
    add_index :scholarships, :scholarship_type_id unless index_exists?(:scholarships, :scholarship_type_id)

    # scholarships
    remove_index :scholarship_durations, name: "index_scholarship_durations_on_scholarship_id" if index_exists?(:scholarship_durations, name: "index_scholarship_durations_on_scholarship_id")
    change_column :scholarships, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :scholarship_durations, :scholarship_id, :integer, limit: 8
    add_index :scholarship_durations, :scholarship_id unless index_exists?(:scholarship_durations, :scholarship_id)

    # sponsors
    remove_index :scholarships, name: "index_scholarships_on_sponsor_id" if index_exists?(:scholarships, name: "index_scholarships_on_sponsor_id")
    change_column :sponsors, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :scholarships, :sponsor_id, :integer, limit: 8
    add_index :scholarships, :sponsor_id unless index_exists?(:scholarships, :sponsor_id)

    # states
    remove_index :cities, name: "index_cities_on_state_id" if index_exists?(:cities, name: "index_cities_on_state_id")
    remove_index :students, name: "index_students_on_state_id" if index_exists?(:students, name: "index_students_on_state_id")
    change_column :states, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :cities, :state_id, :integer, limit: 8
    add_index :cities, :state_id unless index_exists?(:cities, :state_id)
    change_column :students, :birth_state_id, :integer, limit: 8
    add_index :students, :birth_state_id unless index_exists?(:students, :birth_state_id)

    # student_majors
    change_column :student_majors, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # students
    remove_index :enrollments, name: "index_enrollments_on_student_id" if index_exists?(:enrollments, name: "index_enrollments_on_student_id")
    remove_index :student_majors, name: "index_student_majors_on_student_id" if index_exists?(:student_majors, name: "index_student_majors_on_student_id")
    change_column :students, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :enrollments, :student_id, :integer, limit: 8
    add_index :enrollments, :student_id unless index_exists?(:enrollments, :student_id)
    change_column :student_majors, :student_id, :integer, limit: 8
    add_index :student_majors, :student_id unless index_exists?(:student_majors, :student_id)

    # thesis_defense_committee_participations
    change_column :thesis_defense_committee_participations, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true

    # users
    remove_index :professors, name: "index_professors_on_user_id" if index_exists?(:professors, name: "index_professors_on_user_id")
    remove_index :students, name: "index_students_on_user_id" if index_exists?(:students, name: "index_students_on_user_id")
    remove_index :users, name: "index_users_on_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_id")
    remove_index :users, name: "index_users_on_invited_by_type_and_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_type_and_invited_by_id")
    change_column :users, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true
    change_column :professors, :user_id, :integer, limit: 8
    add_index :professors, :user_id unless index_exists?(:professors, :user_id)
    change_column :users, :invited_by_id, :integer, limit: 8
    add_index :users, :invited_by_id unless index_exists?(:users, :invited_by_id)
    change_column :users, :invited_by_id, :integer, limit: 8
    add_index :users, [:invited_by_type, :invited_by_id] unless index_exists?(:users, [:invited_by_type, :invited_by_id])

    # versions
    change_column :versions, :id, :integer, limit: 8, unique: true, null: false, auto_increment: true


    change_column :versions, :item_id, :integer, limit: 8
    add_index :versions, [:item_type, :item_id] unless index_exists?(:versions, [:item_type, :item_id])
    
    add_column :students, :user_id, :integer, limit: 8
    Student.update_all("user_id = temp_user_id")
    remove_column :students, :temp_user_id
    add_index :students, :user_id unless index_exists?(:students, :user_id)

    # new indexes
    add_index :course_research_areas, :course_id unless index_exists?(:course_research_areas, :course_id)
    add_index :course_research_areas, :research_area_id unless index_exists?(:course_research_areas, :research_area_id)
    add_index :enrollments, :research_area_id unless index_exists?(:enrollments, :research_area_id)
    add_index :notifications, :query_id unless index_exists?(:notifications, :query_id)
    add_index :phase_completions, :enrollment_id unless index_exists?(:phase_completions, :enrollment_id)
    add_index :phase_completions, :phase_id unless index_exists?(:phase_completions, :phase_id)
  end

  def down
    # new indexes
    remove_index :course_research_areas, name: "index_course_research_areas_on_course_id" if index_exists?(:course_research_areas, name: "index_course_research_areas_on_course_id")
    remove_index :course_research_areas, name: "index_course_research_areas_on_research_area_id" if index_exists?(:course_research_areas, name: "index_course_research_areas_on_research_area_id")
    remove_index :enrollments, name: "index_enrollments_on_research_area_id" if index_exists?(:enrollments, name: "index_enrollments_on_research_area_id")
    remove_index :notifications, name: "index_notifications_on_query_id" if index_exists?(:notifications, name: "index_notifications_on_query_id")
    remove_index :phase_completions, name: "index_phase_completions_on_enrollment_id" if index_exists?(:phase_completions, name: "index_phase_completions_on_enrollment_id")
    remove_index :phase_completions, name: "index_phase_completions_on_phase_id" if index_exists?(:phase_completions, name: "index_phase_completions_on_phase_id")

    remove_index :versions, name: "index_versions_on_item_type_and_item_id" if index_exists?(:versions, name: "index_versions_on_item_type_and_item_id")
    
    remove_index :students, name: "index_students_on_user_id" if index_exists?(:students, name: "index_students_on_user_id")
    add_column :students, :temp_user_id, :integer
    Student.update_all("temp_user_id = user_id")
    remove_column :students, :user_id

    # accomplishments
    change_column :accomplishments, :id, :integer, unique: true, null: false, auto_increment: true

    # advisement_authorizations
    change_column :advisement_authorizations, :id, :integer, unique: true, null: false, auto_increment: true

    # advisements
    change_column :advisements, :id, :integer, unique: true, null: false, auto_increment: true

    # allocations
    change_column :allocations, :id, :integer, unique: true, null: false, auto_increment: true

    # carrier_wave_files
    change_column :carrier_wave_files, :id, :integer, unique: true, null: false, auto_increment: true

    # cities
    remove_index :professors, name: "index_professors_on_city_id" if index_exists?(:professors, name: "index_professors_on_city_id")
    remove_index :students, name: "index_students_on_birth_city_id" if index_exists?(:students, name: "index_students_on_birth_city_id")
    remove_index :students, name: "index_students_on_city_id" if index_exists?(:students, name: "index_students_on_city_id")
    change_column :cities, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :professors, :city_id, :integer
    add_index :professors, :city_id, name: "index_professors_on_city_id" unless index_exists?(:professors, :city_id)
    change_column :students, :birth_city_id, :integer
    add_index :students, :birth_city_id, name: "index_students_on_birth_city_id" unless index_exists?(:students, :birth_city_id)
    change_column :students, :city_id, :integer
    add_index :students, :city_id, name: "index_students_on_city_id" unless index_exists?(:students, :city_id)

    # class_enrollments
    change_column :class_enrollments, :id, :integer, unique: true, null: false, auto_increment: true

    # countries
    remove_index :professors, name: "index_professors_on_academic_title_country_id" if index_exists?(:professors, name: "index_professors_on_academic_title_country_id")
    remove_index :states, name: "index_states_on_country_id" if index_exists?(:states, name: "index_states_on_country_id")
    remove_index :students, name: "index_students_on_birth_country_id" if index_exists?(:students, name: "index_students_on_birth_country_id")
    change_column :countries, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :professors, :academic_title_country_id, :integer
    add_index :professors, :academic_title_country_id, name: "index_professors_on_academic_title_country_id" unless index_exists?(:professors, :academic_title_country_id)
    change_column :states, :country_id, :integer
    add_index :states, :country_id, name: "index_states_on_country_id" unless index_exists?(:states, :country_id)
    change_column :students, :birth_country_id, :integer
    add_index :students, :birth_country_id, name: "index_students_on_birth_country_id" unless index_exists?(:students, :birth_country_id)

    # course_classes
    remove_index :allocations, name: "index_allocations_on_course_class_id" if index_exists?(:allocations, name: "index_allocations_on_course_class_id")
    remove_index :class_enrollments, name: "index_class_enrollments_on_course_class_id" if index_exists?(:class_enrollments, name: "index_class_enrollments_on_course_class_id")
    change_column :course_classes, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :allocations, :course_class_id, :integer
    add_index :allocations, :course_class_id, name: "index_allocations_on_course_class_id" unless index_exists?(:allocations, :course_class_id)
    change_column :class_enrollments, :course_class_id, :integer
    add_index :class_enrollments, :course_class_id, name: "index_class_enrollments_on_course_class_id" unless index_exists?(:class_enrollments, :course_class_id)

    # course_research_areas
    change_column :course_research_areas, :id, :integer, unique: true, null: false, auto_increment: true

    # course_types
    remove_index :courses, name: "index_courses_on_course_type_id" if index_exists?(:courses, name: "index_courses_on_course_type_id")
    change_column :course_types, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :courses, :course_type_id, :integer
    add_index :courses, :course_type_id, name: "index_courses_on_course_type_id" unless index_exists?(:courses, :course_type_id)

    # courses
    remove_index :course_classes, name: "index_course_classes_on_course_id" if index_exists?(:course_classes, name: "index_course_classes_on_course_id")
    change_column :courses, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :course_classes, :course_id, :integer
    add_index :course_classes, :course_id, name: "index_course_classes_on_course_id" unless index_exists?(:course_classes, :course_id)

    # custom_variables
    change_column :custom_variables, :id, :integer, unique: true, null: false, auto_increment: true

    # deferral_types
    remove_index :deferrals, name: "index_deferrals_on_deferral_type_id" if index_exists?(:deferrals, name: "index_deferrals_on_deferral_type_id")
    change_column :deferral_types, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :deferrals, :deferral_type_id, :integer
    add_index :deferrals, :deferral_type_id, name: "index_deferrals_on_deferral_type_id" unless index_exists?(:deferrals, :deferral_type_id)

    # deferrals
    change_column :deferrals, :id, :integer, unique: true, null: false, auto_increment: true

    # dismissal_reasons
    remove_index :dismissals, name: "index_dismissals_on_dismissal_reason_id" if index_exists?(:dismissals, name: "index_dismissals_on_dismissal_reason_id")
    change_column :dismissal_reasons, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :dismissals, :dismissal_reason_id, :integer
    add_index :dismissals, :dismissal_reason_id, name: "index_dismissals_on_dismissal_reason_id" unless index_exists?(:dismissals, :dismissal_reason_id)

    # dismissals
    change_column :dismissals, :id, :integer, unique: true, null: false, auto_increment: true

    # email_templates
    change_column :email_templates, :id, :integer, unique: true, null: false, auto_increment: true

    # enrollment_holds
    change_column :enrollment_holds, :id, :integer, unique: true, null: false, auto_increment: true

    # enrollment_statuses
    remove_index :enrollments, name: "index_enrollments_on_enrollment_status_id" if index_exists?(:enrollments, name: "index_enrollments_on_enrollment_status_id")
    change_column :enrollment_statuses, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :enrollments, :enrollment_status_id, :integer
    add_index :enrollments, :enrollment_status_id, name: "index_enrollments_on_enrollment_status_id" unless index_exists?(:enrollments, :enrollment_status_id)

    # enrollments
    remove_index :accomplishments, name: "index_accomplishments_on_enrollment_id" if index_exists?(:accomplishments, name: "index_accomplishments_on_enrollment_id")
    remove_index :advisements, name: "index_advisements_on_enrollment_id" if index_exists?(:advisements, name: "index_advisements_on_enrollment_id")
    remove_index :class_enrollments, name: "index_class_enrollments_on_enrollment_id" if index_exists?(:class_enrollments, name: "index_class_enrollments_on_enrollment_id")
    remove_index :deferrals, name: "index_deferrals_on_enrollment_id" if index_exists?(:deferrals, name: "index_deferrals_on_enrollment_id")
    remove_index :dismissals, name: "index_dismissals_on_enrollment_id" if index_exists?(:dismissals, name: "index_dismissals_on_enrollment_id")
    remove_index :enrollment_holds, name: "index_enrollment_holds_on_enrollment_id" if index_exists?(:enrollment_holds, name: "index_enrollment_holds_on_enrollment_id")
    remove_index :scholarship_durations, name: "index_scholarship_durations_on_enrollment_id" if index_exists?(:scholarship_durations, name: "index_scholarship_durations_on_enrollment_id")
    remove_index :thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_enrollment_id" if index_exists?(:thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_enrollment_id")
    change_column :enrollments, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :accomplishments, :enrollment_id, :integer
    add_index :accomplishments, :enrollment_id, name: "index_accomplishments_on_enrollment_id" unless index_exists?(:accomplishments, :enrollment_id)
    change_column :advisements, :enrollment_id, :integer
    add_index :advisements, :enrollment_id, name: "index_advisements_on_enrollment_id" unless index_exists?(:advisements, :enrollment_id)
    change_column :class_enrollments, :enrollment_id, :integer
    add_index :class_enrollments, :enrollment_id, name: "index_class_enrollments_on_enrollment_id" unless index_exists?(:class_enrollments, :enrollment_id)
    change_column :deferrals, :enrollment_id, :integer
    add_index :deferrals, :enrollment_id, name: "index_deferrals_on_enrollment_id" unless index_exists?(:deferrals, :enrollment_id)
    change_column :dismissals, :enrollment_id, :integer
    add_index :dismissals, :enrollment_id, name: "index_dismissals_on_enrollment_id" unless index_exists?(:dismissals, :enrollment_id)
    change_column :enrollment_holds, :enrollment_id, :integer
    add_index :enrollment_holds, :enrollment_id, name: "index_enrollment_holds_on_enrollment_id" unless index_exists?(:enrollment_holds, :enrollment_id)
    change_column :scholarship_durations, :enrollment_id, :integer
    add_index :scholarship_durations, :enrollment_id, name: "index_scholarship_durations_on_enrollment_id" unless index_exists?(:scholarship_durations, :enrollment_id)
    change_column :thesis_defense_committee_participations, :enrollment_id, :integer
    add_index :thesis_defense_committee_participations, :enrollment_id, name: "index_thesis_defense_committee_participations_on_enrollment_id" unless index_exists?(:thesis_defense_committee_participations, :enrollment_id)

    # institutions
    remove_index :majors, name: "index_majors_on_institution_id" if index_exists?(:majors, name: "index_majors_on_institution_id")
    remove_index :professors, name: "index_professors_on_academic_title_institution_id" if index_exists?(:professors, name: "index_professors_on_academic_title_institution_id")
    remove_index :professors, name: "index_professors_on_institution_id" if index_exists?(:professors, name: "index_professors_on_institution_id")
    change_column :institutions, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :majors, :institution_id, :integer
    add_index :majors, :institution_id, name: "index_majors_on_institution_id" unless index_exists?(:majors, :institution_id)
    change_column :professors, :academic_title_institution_id, :integer
    add_index :professors, :academic_title_institution_id, name: "index_professors_on_academic_title_institution_id" unless index_exists?(:professors, :academic_title_institution_id)
    change_column :professors, :institution_id, :integer
    add_index :professors, :institution_id, name: "index_professors_on_institution_id" unless index_exists?(:professors, :institution_id)

    # levels
    remove_index :advisement_authorizations, name: "index_advisement_authorizations_on_level_id" if index_exists?(:advisement_authorizations, name: "index_advisement_authorizations_on_level_id")
    remove_index :enrollments, name: "index_enrollments_on_level_id" if index_exists?(:enrollments, name: "index_enrollments_on_level_id")
    remove_index :majors, name: "index_majors_on_level_id" if index_exists?(:majors, name: "index_majors_on_level_id")
    remove_index :phase_durations, name: "index_phase_durations_on_level_id" if index_exists?(:phase_durations, name: "index_phase_durations_on_level_id")
    remove_index :professors, name: "index_professors_on_academic_title_level_id" if index_exists?(:professors, name: "index_professors_on_academic_title_level_id")
    remove_index :scholarships, name: "index_scholarships_on_level_id" if index_exists?(:scholarships, name: "index_scholarships_on_level_id")
    change_column :levels, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :advisement_authorizations, :level_id, :integer
    add_index :advisement_authorizations, :level_id, name: "index_advisement_authorizations_on_level_id" unless index_exists?(:advisement_authorizations, :level_id)
    change_column :enrollments, :level_id, :integer
    add_index :enrollments, :level_id, name: "index_enrollments_on_level_id" unless index_exists?(:enrollments, :level_id)
    change_column :majors, :level_id, :integer
    add_index :majors, :level_id, name: "index_majors_on_level_id" unless index_exists?(:majors, :level_id)
    change_column :phase_durations, :level_id, :integer
    add_index :phase_durations, :level_id, name: "index_phase_durations_on_level_id" unless index_exists?(:phase_durations, :level_id)
    change_column :professors, :academic_title_level_id, :integer
    add_index :professors, :academic_title_level_id, name: "index_professors_on_academic_title_level_id" unless index_exists?(:professors, :academic_title_level_id)
    change_column :scholarships, :level_id, :integer
    add_index :scholarships, :level_id, name: "index_scholarships_on_level_id" unless index_exists?(:scholarships, :level_id)

    # majors
    remove_index :student_majors, name: "index_student_majors_on_major_id" if index_exists?(:student_majors, name: "index_student_majors_on_major_id")
    change_column :majors, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :student_majors, :major_id, :integer
    add_index :student_majors, :major_id, name: "index_student_majors_on_major_id" unless index_exists?(:student_majors, :major_id)

    # notification_logs
    change_column :notification_logs, :id, :integer, unique: true, null: false, auto_increment: true

    # notification_params
    change_column :notification_params, :id, :integer, unique: true, null: false, auto_increment: true

    # notifications
    remove_index :notification_logs, name: "index_notification_logs_on_notification_id" if index_exists?(:notification_logs, name: "index_notification_logs_on_notification_id")
    remove_index :notification_params, name: "index_notification_params_on_notification_id" if index_exists?(:notification_params, name: "index_notification_params_on_notification_id")
    change_column :notifications, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :notification_logs, :notification_id, :integer
    add_index :notification_logs, :notification_id, name: "index_notification_logs_on_notification_id" unless index_exists?(:notification_logs, :notification_id)
    change_column :notification_params, :notification_id, :integer
    add_index :notification_params, :notification_id, name: "index_notification_params_on_notification_id" unless index_exists?(:notification_params, :notification_id)

    # phase_completions
    change_column :phase_completions, :id, :integer, unique: true, null: false, auto_increment: true

    # phase_durations
    change_column :phase_durations, :id, :integer, unique: true, null: false, auto_increment: true

    # phases
    remove_index :accomplishments, name: "index_accomplishments_on_phase_id" if index_exists?(:accomplishments, name: "index_accomplishments_on_phase_id")
    remove_index :deferral_types, name: "index_deferral_types_on_phase_id" if index_exists?(:deferral_types, name: "index_deferral_types_on_phase_id")
    remove_index :phase_durations, name: "index_phase_durations_on_phase_id" if index_exists?(:phase_durations, name: "index_phase_durations_on_phase_id")
    change_column :phases, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :accomplishments, :phase_id, :integer
    add_index :accomplishments, :phase_id, name: "index_accomplishments_on_phase_id" unless index_exists?(:accomplishments, :phase_id)
    change_column :deferral_types, :phase_id, :integer
    add_index :deferral_types, :phase_id, name: "index_deferral_types_on_phase_id" unless index_exists?(:deferral_types, :phase_id)
    change_column :phase_durations, :phase_id, :integer
    add_index :phase_durations, :phase_id, name: "index_phase_durations_on_phase_id" unless index_exists?(:phase_durations, :phase_id)

    # professor_research_areas
    change_column :professor_research_areas, :id, :integer, unique: true, null: false, auto_increment: true

    # professors
    remove_index :advisement_authorizations, name: "index_advisement_authorizations_on_professor_id" if index_exists?(:advisement_authorizations, name: "index_advisement_authorizations_on_professor_id")
    remove_index :advisements, name: "index_advisements_on_professor_id" if index_exists?(:advisements, name: "index_advisements_on_professor_id")
    remove_index :course_classes, name: "index_course_classes_on_professor_id" if index_exists?(:course_classes, name: "index_course_classes_on_professor_id")
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_professor_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_professor_id")
    remove_index :scholarships, name: "index_scholarships_on_professor_id" if index_exists?(:scholarships, name: "index_scholarships_on_professor_id")
    remove_index :thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id" if index_exists?(:thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id")
    change_column :professors, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :advisement_authorizations, :professor_id, :integer
    add_index :advisement_authorizations, :professor_id, name: "index_advisement_authorizations_on_professor_id" unless index_exists?(:advisement_authorizations, :professor_id)
    change_column :advisements, :professor_id, :integer
    add_index :advisements, :professor_id, name: "index_advisements_on_professor_id" unless index_exists?(:advisements, :professor_id)
    change_column :course_classes, :professor_id, :integer
    add_index :course_classes, :professor_id, name: "index_course_classes_on_professor_id" unless index_exists?(:course_classes, :professor_id)
    change_column :professor_research_areas, :professor_id, :integer
    add_index :professor_research_areas, :professor_id, name: "index_professor_research_areas_on_professor_id" unless index_exists?(:professor_research_areas, :professor_id)
    change_column :scholarships, :professor_id, :integer
    add_index :scholarships, :professor_id, name: "index_scholarships_on_professor_id" unless index_exists?(:scholarships, :professor_id)
    change_column :thesis_defense_committee_participations, :professor_id, :integer
    add_index :thesis_defense_committee_participations, :professor_id, name: "index_thesis_defense_committee_participations_on_professor_id" unless index_exists?(:thesis_defense_committee_participations, :professor_id)

    # queries
    remove_index :query_params, name: "index_query_params_on_query_id" if index_exists?(:query_params, name: "index_query_params_on_query_id")
    change_column :queries, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :query_params, :query_id, :integer
    add_index :query_params, :query_id, name: "index_query_params_on_query_id" unless index_exists?(:query_params, :query_id)

    # query_params
    remove_index :notification_params, name: "index_notification_params_on_query_param_id" if index_exists?(:notification_params, name: "index_notification_params_on_query_param_id")
    change_column :query_params, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :notification_params, :query_param_id, :integer
    add_index :notification_params, :query_param_id, name: "index_notification_params_on_query_param_id" unless index_exists?(:notification_params, :query_param_id)

    # report_configurations
    change_column :report_configurations, :id, :integer, unique: true, null: false, auto_increment: true

    # research_areas
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_research_area_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_research_area_id")
    change_column :research_areas, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :professor_research_areas, :research_area_id, :integer
    add_index :professor_research_areas, :research_area_id, name: "index_professor_research_areas_on_research_area_id" unless index_exists?(:professor_research_areas, :research_area_id)

    # roles
    remove_index :users, name: "index_users_on_role_id" if index_exists?(:users, name: "index_users_on_role_id")
    change_column :roles, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :users, :role_id, :integer
    add_index :users, :role_id, name: "index_users_on_role_id" unless index_exists?(:users, :role_id)

    # scholarship_durations
    remove_index :scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id" if index_exists?(:scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id")
    change_column :scholarship_durations, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :scholarship_suspensions, :scholarship_duration_id, :integer
    add_index :scholarship_suspensions, :scholarship_duration_id, name: "index_scholarship_suspensions_on_scholarship_duration_id" unless index_exists?(:scholarship_suspensions, :scholarship_duration_id)

    # scholarship_suspensions
    change_column :scholarship_suspensions, :id, :integer, unique: true, null: false, auto_increment: true

    # scholarship_types
    remove_index :scholarships, name: "index_scholarships_on_scholarship_type_id" if index_exists?(:scholarships, name: "index_scholarships_on_scholarship_type_id")
    change_column :scholarship_types, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :scholarships, :scholarship_type_id, :integer
    add_index :scholarships, :scholarship_type_id, name: "index_scholarships_on_scholarship_type_id" unless index_exists?(:scholarships, :scholarship_type_id)

    # scholarships
    remove_index :scholarship_durations, name: "index_scholarship_durations_on_scholarship_id" if index_exists?(:scholarship_durations, name: "index_scholarship_durations_on_scholarship_id")
    change_column :scholarships, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :scholarship_durations, :scholarship_id, :integer
    add_index :scholarship_durations, :scholarship_id, name: "index_scholarship_durations_on_scholarship_id" unless index_exists?(:scholarship_durations, :scholarship_id)

    # sponsors
    remove_index :scholarships, name: "index_scholarships_on_sponsor_id" if index_exists?(:scholarships, name: "index_scholarships_on_sponsor_id")
    change_column :sponsors, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :scholarships, :sponsor_id, :integer
    add_index :scholarships, :sponsor_id, name: "index_scholarships_on_sponsor_id" unless index_exists?(:scholarships, :sponsor_id)

    # states
    remove_index :cities, name: "index_cities_on_state_id" if index_exists?(:cities, name: "index_cities_on_state_id")
    remove_index :students, name: "index_students_on_birth_state_id" if index_exists?(:students, name: "index_students_on_birth_state_id")
    change_column :states, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :cities, :state_id, :integer
    add_index :cities, :state_id, name: "index_cities_on_state_id" unless index_exists?(:cities, :state_id)
    change_column :students, :birth_state_id, :integer
    add_index :students, :birth_state_id, name: "index_students_on_state_id" unless index_exists?(:students, :birth_state_id)

    # student_majors
    change_column :student_majors, :id, :integer, unique: true, null: false, auto_increment: true

    # students
    remove_index :enrollments, name: "index_enrollments_on_student_id" if index_exists?(:enrollments, name: "index_enrollments_on_student_id")
    remove_index :student_majors, name: "index_student_majors_on_student_id" if index_exists?(:student_majors, name: "index_student_majors_on_student_id")
    change_column :students, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :enrollments, :student_id, :integer
    add_index :enrollments, :student_id, name: "index_enrollments_on_student_id" unless index_exists?(:enrollments, :student_id)
    change_column :student_majors, :student_id, :integer
    add_index :student_majors, :student_id, name: "index_student_majors_on_student_id" unless index_exists?(:student_majors, :student_id)

    # thesis_defense_committee_participations
    change_column :thesis_defense_committee_participations, :id, :integer, unique: true, null: false, auto_increment: true

    # users
    remove_index :professors, name: "index_professors_on_user_id" if index_exists?(:professors, name: "index_professors_on_user_id")
    remove_index :students, name: "index_students_on_user_id" if index_exists?(:students, name: "index_students_on_user_id")
    remove_index :users, name: "index_users_on_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_id")
    remove_index :users, name: "index_users_on_invited_by_type_and_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_type_and_invited_by_id")
    change_column :users, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :professors, :user_id, :integer
    add_index :professors, :user_id, name: "index_professors_on_user_id" unless index_exists?(:professors, :user_id)
    change_column :users, :invited_by_id, :integer
    add_index :users, :invited_by_id, name: "index_users_on_invited_by_id" unless index_exists?(:users, :invited_by_id)
    change_column :users, :invited_by_id, :integer
    add_index :users, [:invited_by_type, :invited_by_id], name: "index_users_on_invited_by_type_and_invited_by_id" unless index_exists?(:users, [:invited_by_type, :invited_by_id])

    # versions
    change_column :versions, :id, :integer, unique: true, null: false, auto_increment: true
    change_column :versions, :item_id, :integer
    add_index :versions, [:item_type, :item_id] unless index_exists?(:versions, [:item_type, :item_id])
    
    add_reference :students, :user, foreign_key: { on_delete: :nullify }
    Student.update_all("user_id = temp_user_id")
    remove_column :students, :temp_user_id
  end
end