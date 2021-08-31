class MigrateIdsToBigint < ActiveRecord::Migration[6.0]
  def up
    remove_index :versions, name: "index_versions_on_item_type_and_item_id" if index_exists?(:versions, name: "index_versions_on_item_type_and_item_id")
    add_column :students, :temp_user_id, :bigint
    Student.update_all("temp_user_id = user_id")
    remove_reference :students, :user

    # accomplishments
    change_column :accomplishments, :id, :bigint

    # advisement_authorizations
    change_column :advisement_authorizations, :id, :bigint

    # advisements
    change_column :advisements, :id, :bigint

    # allocations
    change_column :allocations, :id, :bigint

    # carrier_wave_files
    change_column :carrier_wave_files, :id, :bigint

    # cities
    remove_index :professors, name: "index_professors_on_city_id" if index_exists?(:professors, name: "index_professors_on_city_id")
    remove_index :students, name: "index_students_on_birth_city_id" if index_exists?(:students, name: "index_students_on_birth_city_id")
    remove_index :students, name: "index_students_on_city_id" if index_exists?(:students, name: "index_students_on_city_id")
    change_column :cities, :id, :bigint
    change_column :professors, :city_id, :bigint
    add_index :professors, :city_id unless index_exists?(:professors, :city_id)
    change_column :students, :birth_city_id, :bigint
    add_index :students, :birth_city_id unless index_exists?(:students, :birth_city_id)
    change_column :students, :city_id, :bigint
    add_index :students, :city_id unless index_exists?(:students, :city_id)

    # class_enrollments
    change_column :class_enrollments, :id, :bigint

    # countries
    remove_index :professors, name: "index_professors_on_academic_title_country_id" if index_exists?(:professors, name: "index_professors_on_academic_title_country_id")
    remove_index :states, name: "index_states_on_country_id" if index_exists?(:states, name: "index_states_on_country_id")
    remove_index :students, name: "index_students_on_birth_country_id" if index_exists?(:students, name: "index_students_on_birth_country_id")
    change_column :countries, :id, :bigint
    change_column :professors, :academic_title_country_id, :bigint
    add_index :professors, :academic_title_country_id unless index_exists?(:professors, :academic_title_country_id)
    change_column :states, :country_id, :bigint
    add_index :states, :country_id unless index_exists?(:states, :country_id)
    change_column :students, :birth_country_id, :bigint
    add_index :students, :birth_country_id unless index_exists?(:students, :birth_country_id)

    # course_classes
    remove_index :allocations, name: "index_allocations_on_course_class_id" if index_exists?(:allocations, name: "index_allocations_on_course_class_id")
    remove_index :class_enrollments, name: "index_class_enrollments_on_course_class_id" if index_exists?(:class_enrollments, name: "index_class_enrollments_on_course_class_id")
    change_column :course_classes, :id, :bigint
    change_column :allocations, :course_class_id, :bigint
    add_index :allocations, :course_class_id unless index_exists?(:allocations, :course_class_id)
    change_column :class_enrollments, :course_class_id, :bigint
    add_index :class_enrollments, :course_class_id unless index_exists?(:class_enrollments, :course_class_id)

    # course_research_areas
    change_column :course_research_areas, :id, :bigint

    # course_types
    remove_index :courses, name: "index_courses_on_course_type_id" if index_exists?(:courses, name: "index_courses_on_course_type_id")
    change_column :course_types, :id, :bigint
    change_column :courses, :course_type_id, :bigint
    add_index :courses, :course_type_id unless index_exists?(:courses, :course_type_id)

    # courses
    remove_index :course_classes, name: "index_course_classes_on_course_id" if index_exists?(:course_classes, name: "index_course_classes_on_course_id")
    change_column :courses, :id, :bigint
    change_column :course_classes, :course_id, :bigint
    add_index :course_classes, :course_id unless index_exists?(:course_classes, :course_id)

    # custom_variables
    change_column :custom_variables, :id, :bigint

    # deferral_types
    remove_index :deferrals, name: "index_deferrals_on_deferral_type_id" if index_exists?(:deferrals, name: "index_deferrals_on_deferral_type_id")
    change_column :deferral_types, :id, :bigint
    change_column :deferrals, :deferral_type_id, :bigint
    add_index :deferrals, :deferral_type_id unless index_exists?(:deferrals, :deferral_type_id)

    # deferrals
    change_column :deferrals, :id, :bigint

    # dismissal_reasons
    remove_index :dismissals, name: "index_dismissals_on_dismissal_reason_id" if index_exists?(:dismissals, name: "index_dismissals_on_dismissal_reason_id")
    change_column :dismissal_reasons, :id, :bigint
    change_column :dismissals, :dismissal_reason_id, :bigint
    add_index :dismissals, :dismissal_reason_id unless index_exists?(:dismissals, :dismissal_reason_id)

    # dismissals
    change_column :dismissals, :id, :bigint

    # email_templates
    change_column :email_templates, :id, :bigint

    # enrollment_holds
    change_column :enrollment_holds, :id, :bigint

    # enrollment_statuses
    remove_index :enrollments, name: "index_enrollments_on_enrollment_status_id" if index_exists?(:enrollments, name: "index_enrollments_on_enrollment_status_id")
    change_column :enrollment_statuses, :id, :bigint
    change_column :enrollments, :enrollment_status_id, :bigint
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
    change_column :enrollments, :id, :bigint
    change_column :accomplishments, :enrollment_id, :bigint
    add_index :accomplishments, :enrollment_id unless index_exists?(:accomplishments, :enrollment_id)
    change_column :advisements, :enrollment_id, :bigint
    add_index :advisements, :enrollment_id unless index_exists?(:advisements, :enrollment_id)
    change_column :class_enrollments, :enrollment_id, :bigint
    add_index :class_enrollments, :enrollment_id unless index_exists?(:class_enrollments, :enrollment_id)
    change_column :deferrals, :enrollment_id, :bigint
    add_index :deferrals, :enrollment_id unless index_exists?(:deferrals, :enrollment_id)
    change_column :dismissals, :enrollment_id, :bigint
    add_index :dismissals, :enrollment_id unless index_exists?(:dismissals, :enrollment_id)
    change_column :enrollment_holds, :enrollment_id, :bigint
    add_index :enrollment_holds, :enrollment_id unless index_exists?(:enrollment_holds, :enrollment_id)
    change_column :scholarship_durations, :enrollment_id, :bigint
    add_index :scholarship_durations, :enrollment_id unless index_exists?(:scholarship_durations, :enrollment_id)
    change_column :thesis_defense_committee_participations, :enrollment_id, :bigint
    add_index :thesis_defense_committee_participations, :enrollment_id unless index_exists?(:thesis_defense_committee_participations, :enrollment_id)

    # institutions
    remove_index :majors, name: "index_majors_on_institution_id" if index_exists?(:majors, name: "index_majors_on_institution_id")
    remove_index :professors, name: "index_professors_on_academic_title_institution_id" if index_exists?(:professors, name: "index_professors_on_academic_title_institution_id")
    remove_index :professors, name: "index_professors_on_institution_id" if index_exists?(:professors, name: "index_professors_on_institution_id")
    change_column :institutions, :id, :bigint
    change_column :majors, :institution_id, :bigint
    add_index :majors, :institution_id unless index_exists?(:majors, :institution_id)
    change_column :professors, :academic_title_institution_id, :bigint
    add_index :professors, :academic_title_institution_id unless index_exists?(:professors, :academic_title_institution_id)
    change_column :professors, :institution_id, :bigint
    add_index :professors, :institution_id unless index_exists?(:professors, :institution_id)

    # levels
    remove_index :advisement_authorizations, name: "index_advisement_authorizations_on_level_id" if index_exists?(:advisement_authorizations, name: "index_advisement_authorizations_on_level_id")
    remove_index :enrollments, name: "index_enrollments_on_level_id" if index_exists?(:enrollments, name: "index_enrollments_on_level_id")
    remove_index :majors, name: "index_majors_on_level_id" if index_exists?(:majors, name: "index_majors_on_level_id")
    remove_index :phase_durations, name: "index_phase_durations_on_level_id" if index_exists?(:phase_durations, name: "index_phase_durations_on_level_id")
    remove_index :professors, name: "index_professors_on_academic_title_level_id" if index_exists?(:professors, name: "index_professors_on_academic_title_level_id")
    remove_index :scholarships, name: "index_scholarships_on_level_id" if index_exists?(:scholarships, name: "index_scholarships_on_level_id")
    change_column :levels, :id, :bigint
    change_column :advisement_authorizations, :level_id, :bigint
    add_index :advisement_authorizations, :level_id unless index_exists?(:advisement_authorizations, :level_id)
    change_column :enrollments, :level_id, :bigint
    add_index :enrollments, :level_id unless index_exists?(:enrollments, :level_id)
    change_column :majors, :level_id, :bigint
    add_index :majors, :level_id unless index_exists?(:majors, :level_id)
    change_column :phase_durations, :level_id, :bigint
    add_index :phase_durations, :level_id unless index_exists?(:phase_durations, :level_id)
    change_column :professors, :academic_title_level_id, :bigint
    add_index :professors, :academic_title_level_id unless index_exists?(:professors, :academic_title_level_id)
    change_column :scholarships, :level_id, :bigint
    add_index :scholarships, :level_id unless index_exists?(:scholarships, :level_id)

    # majors
    remove_index :student_majors, name: "index_student_majors_on_major_id" if index_exists?(:student_majors, name: "index_student_majors_on_major_id")
    change_column :majors, :id, :bigint
    change_column :student_majors, :major_id, :bigint
    add_index :student_majors, :major_id unless index_exists?(:student_majors, :major_id)

    # notification_logs
    change_column :notification_logs, :id, :bigint

    # notification_params
    change_column :notification_params, :id, :bigint

    # notifications
    remove_index :notification_logs, name: "index_notification_logs_on_notification_id" if index_exists?(:notification_logs, name: "index_notification_logs_on_notification_id")
    remove_index :notification_params, name: "index_notification_params_on_notification_id" if index_exists?(:notification_params, name: "index_notification_params_on_notification_id")
    change_column :notifications, :id, :bigint
    change_column :notification_logs, :notification_id, :bigint
    add_index :notification_logs, :notification_id unless index_exists?(:notification_logs, :notification_id)
    change_column :notification_params, :notification_id, :bigint
    add_index :notification_params, :notification_id unless index_exists?(:notification_params, :notification_id)

    # phase_completions
    change_column :phase_completions, :id, :bigint

    # phase_durations
    change_column :phase_durations, :id, :bigint

    # phases
    remove_index :accomplishments, name: "index_accomplishments_on_phase_id" if index_exists?(:accomplishments, name: "index_accomplishments_on_phase_id")
    remove_index :deferral_types, name: "index_deferral_types_on_phase_id" if index_exists?(:deferral_types, name: "index_deferral_types_on_phase_id")
    remove_index :phase_durations, name: "index_phase_durations_on_phase_id" if index_exists?(:phase_durations, name: "index_phase_durations_on_phase_id")
    change_column :phases, :id, :bigint
    change_column :accomplishments, :phase_id, :bigint
    add_index :accomplishments, :phase_id unless index_exists?(:accomplishments, :phase_id)
    change_column :deferral_types, :phase_id, :bigint
    add_index :deferral_types, :phase_id unless index_exists?(:deferral_types, :phase_id)
    change_column :phase_durations, :phase_id, :bigint
    add_index :phase_durations, :phase_id unless index_exists?(:phase_durations, :phase_id)

    # professor_research_areas
    change_column :professor_research_areas, :id, :bigint

    # professors
    remove_index :advisement_authorizations, name: "index_advisement_authorizations_on_professor_id" if index_exists?(:advisement_authorizations, name: "index_advisement_authorizations_on_professor_id")
    remove_index :advisements, name: "index_advisements_on_professor_id" if index_exists?(:advisements, name: "index_advisements_on_professor_id")
    remove_index :course_classes, name: "index_course_classes_on_professor_id" if index_exists?(:course_classes, name: "index_course_classes_on_professor_id")
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_professor_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_professor_id")
    remove_index :scholarships, name: "index_scholarships_on_professor_id" if index_exists?(:scholarships, name: "index_scholarships_on_professor_id")
    remove_index :thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id" if index_exists?(:thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id")
    change_column :professors, :id, :bigint
    change_column :advisement_authorizations, :professor_id, :bigint
    add_index :advisement_authorizations, :professor_id unless index_exists?(:advisement_authorizations, :professor_id)
    change_column :advisements, :professor_id, :bigint
    add_index :advisements, :professor_id unless index_exists?(:advisements, :professor_id)
    change_column :course_classes, :professor_id, :bigint
    add_index :course_classes, :professor_id unless index_exists?(:course_classes, :professor_id)
    change_column :professor_research_areas, :professor_id, :bigint
    add_index :professor_research_areas, :professor_id unless index_exists?(:professor_research_areas, :professor_id)
    change_column :scholarships, :professor_id, :bigint
    add_index :scholarships, :professor_id unless index_exists?(:scholarships, :professor_id)
    change_column :thesis_defense_committee_participations, :professor_id, :bigint
    add_index :thesis_defense_committee_participations, :professor_id unless index_exists?(:thesis_defense_committee_participations, :professor_id)

    # queries
    remove_index :query_params, name: "index_query_params_on_query_id" if index_exists?(:query_params, name: "index_query_params_on_query_id")
    change_column :queries, :id, :bigint
    change_column :query_params, :query_id, :bigint
    add_index :query_params, :query_id unless index_exists?(:query_params, :query_id)

    # query_params
    remove_index :notification_params, name: "index_notification_params_on_query_param_id" if index_exists?(:notification_params, name: "index_notification_params_on_query_param_id")
    change_column :query_params, :id, :bigint
    change_column :notification_params, :query_param_id, :bigint
    add_index :notification_params, :query_param_id unless index_exists?(:notification_params, :query_param_id)

    # report_configurations
    change_column :report_configurations, :id, :bigint

    # research_areas
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_research_area_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_research_area_id")
    change_column :research_areas, :id, :bigint
    change_column :professor_research_areas, :research_area_id, :bigint
    add_index :professor_research_areas, :research_area_id unless index_exists?(:professor_research_areas, :research_area_id)

    # roles
    remove_index :users, name: "index_users_on_role_id" if index_exists?(:users, name: "index_users_on_role_id")
    change_column :roles, :id, :bigint
    change_column :users, :role_id, :bigint
    add_index :users, :role_id unless index_exists?(:users, :role_id)

    # scholarship_durations
    remove_index :scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id" if index_exists?(:scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id")
    change_column :scholarship_durations, :id, :bigint
    change_column :scholarship_suspensions, :scholarship_duration_id, :bigint
    add_index :scholarship_suspensions, :scholarship_duration_id unless index_exists?(:scholarship_suspensions, :scholarship_duration_id)

    # scholarship_suspensions
    change_column :scholarship_suspensions, :id, :bigint

    # scholarship_types
    remove_index :scholarships, name: "index_scholarships_on_scholarship_type_id" if index_exists?(:scholarships, name: "index_scholarships_on_scholarship_type_id")
    change_column :scholarship_types, :id, :bigint
    change_column :scholarships, :scholarship_type_id, :bigint
    add_index :scholarships, :scholarship_type_id unless index_exists?(:scholarships, :scholarship_type_id)

    # scholarships
    remove_index :scholarship_durations, name: "index_scholarship_durations_on_scholarship_id" if index_exists?(:scholarship_durations, name: "index_scholarship_durations_on_scholarship_id")
    change_column :scholarships, :id, :bigint
    change_column :scholarship_durations, :scholarship_id, :bigint
    add_index :scholarship_durations, :scholarship_id unless index_exists?(:scholarship_durations, :scholarship_id)

    # sponsors
    remove_index :scholarships, name: "index_scholarships_on_sponsor_id" if index_exists?(:scholarships, name: "index_scholarships_on_sponsor_id")
    change_column :sponsors, :id, :bigint
    change_column :scholarships, :sponsor_id, :bigint
    add_index :scholarships, :sponsor_id unless index_exists?(:scholarships, :sponsor_id)

    # states
    remove_index :cities, name: "index_cities_on_state_id" if index_exists?(:cities, name: "index_cities_on_state_id")
    remove_index :students, name: "index_students_on_state_id" if index_exists?(:students, name: "index_students_on_state_id")
    change_column :states, :id, :bigint
    change_column :cities, :state_id, :bigint
    add_index :cities, :state_id unless index_exists?(:cities, :state_id)
    change_column :students, :birth_state_id, :bigint
    add_index :students, :birth_state_id unless index_exists?(:students, :birth_state_id)

    # student_majors
    change_column :student_majors, :id, :bigint

    # students
    remove_index :enrollments, name: "index_enrollments_on_student_id" if index_exists?(:enrollments, name: "index_enrollments_on_student_id")
    remove_index :student_majors, name: "index_student_majors_on_student_id" if index_exists?(:student_majors, name: "index_student_majors_on_student_id")
    change_column :students, :id, :bigint
    change_column :enrollments, :student_id, :bigint
    add_index :enrollments, :student_id unless index_exists?(:enrollments, :student_id)
    change_column :student_majors, :student_id, :bigint
    add_index :student_majors, :student_id unless index_exists?(:student_majors, :student_id)

    # thesis_defense_committee_participations
    change_column :thesis_defense_committee_participations, :id, :bigint

    # users
    remove_index :professors, name: "index_professors_on_user_id" if index_exists?(:professors, name: "index_professors_on_user_id")
    remove_index :students, name: "index_students_on_user_id" if index_exists?(:students, name: "index_students_on_user_id")
    remove_index :users, name: "index_users_on_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_id")
    remove_index :users, name: "index_users_on_invited_by_type_and_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_type_and_invited_by_id")
    change_column :users, :id, :bigint
    change_column :professors, :user_id, :bigint
    add_index :professors, :user_id unless index_exists?(:professors, :user_id)
    change_column :users, :invited_by_id, :bigint
    add_index :users, :invited_by_id unless index_exists?(:users, :invited_by_id)
    change_column :users, :invited_by_id, :bigint
    add_index :users, [:invited_by_type, :invited_by_id] unless index_exists?(:users, [:invited_by_type, :invited_by_id])

    # versions
    change_column :versions, :id, :bigint


    change_column :versions, :item_id, :bigint
    add_index :versions, [:item_type, :item_id] unless index_exists?(:versions, [:item_type, :item_id])
    add_reference :students, :user, foreign_key: { on_delete: :nullify }
    Student.update_all("user_id = temp_user_id")
    remove_column :students, :temp_user_id

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
    add_column :students, :temp_user_id, :integer
    Student.update_all("temp_user_id = user_id")
    remove_reference :students, :user

    # accomplishments
    change_column :accomplishments, :id, :integer

    # advisement_authorizations
    change_column :advisement_authorizations, :id, :integer

    # advisements
    change_column :advisements, :id, :integer

    # allocations
    change_column :allocations, :id, :integer

    # carrier_wave_files
    change_column :carrier_wave_files, :id, :integer

    # cities
    remove_index :professors, name: "index_professors_on_city_id" if index_exists?(:professors, name: "index_professors_on_city_id")
    remove_index :students, name: "index_students_on_birth_city_id" if index_exists?(:students, name: "index_students_on_birth_city_id")
    remove_index :students, name: "index_students_on_city_id" if index_exists?(:students, name: "index_students_on_city_id")
    change_column :cities, :id, :integer
    change_column :professors, :city_id, :integer
    add_index :professors, :city_id, name: "index_professors_on_city_id" unless index_exists?(:professors, :city_id)
    change_column :students, :birth_city_id, :integer
    add_index :students, :birth_city_id, name: "index_students_on_birth_city_id" unless index_exists?(:students, :birth_city_id)
    change_column :students, :city_id, :integer
    add_index :students, :city_id, name: "index_students_on_city_id" unless index_exists?(:students, :city_id)

    # class_enrollments
    change_column :class_enrollments, :id, :integer

    # countries
    remove_index :professors, name: "index_professors_on_academic_title_country_id" if index_exists?(:professors, name: "index_professors_on_academic_title_country_id")
    remove_index :states, name: "index_states_on_country_id" if index_exists?(:states, name: "index_states_on_country_id")
    remove_index :students, name: "index_students_on_birth_country_id" if index_exists?(:students, name: "index_students_on_birth_country_id")
    change_column :countries, :id, :integer
    change_column :professors, :academic_title_country_id, :integer
    add_index :professors, :academic_title_country_id, name: "index_professors_on_academic_title_country_id" unless index_exists?(:professors, :academic_title_country_id)
    change_column :states, :country_id, :integer
    add_index :states, :country_id, name: "index_states_on_country_id" unless index_exists?(:states, :country_id)
    change_column :students, :birth_country_id, :integer
    add_index :students, :birth_country_id, name: "index_students_on_birth_country_id" unless index_exists?(:students, :birth_country_id)

    # course_classes
    remove_index :allocations, name: "index_allocations_on_course_class_id" if index_exists?(:allocations, name: "index_allocations_on_course_class_id")
    remove_index :class_enrollments, name: "index_class_enrollments_on_course_class_id" if index_exists?(:class_enrollments, name: "index_class_enrollments_on_course_class_id")
    change_column :course_classes, :id, :integer
    change_column :allocations, :course_class_id, :integer
    add_index :allocations, :course_class_id, name: "index_allocations_on_course_class_id" unless index_exists?(:allocations, :course_class_id)
    change_column :class_enrollments, :course_class_id, :integer
    add_index :class_enrollments, :course_class_id, name: "index_class_enrollments_on_course_class_id" unless index_exists?(:class_enrollments, :course_class_id)

    # course_research_areas
    change_column :course_research_areas, :id, :integer

    # course_types
    remove_index :courses, name: "index_courses_on_course_type_id" if index_exists?(:courses, name: "index_courses_on_course_type_id")
    change_column :course_types, :id, :integer
    change_column :courses, :course_type_id, :integer
    add_index :courses, :course_type_id, name: "index_courses_on_course_type_id" unless index_exists?(:courses, :course_type_id)

    # courses
    remove_index :course_classes, name: "index_course_classes_on_course_id" if index_exists?(:course_classes, name: "index_course_classes_on_course_id")
    change_column :courses, :id, :integer
    change_column :course_classes, :course_id, :integer
    add_index :course_classes, :course_id, name: "index_course_classes_on_course_id" unless index_exists?(:course_classes, :course_id)

    # custom_variables
    change_column :custom_variables, :id, :integer

    # deferral_types
    remove_index :deferrals, name: "index_deferrals_on_deferral_type_id" if index_exists?(:deferrals, name: "index_deferrals_on_deferral_type_id")
    change_column :deferral_types, :id, :integer
    change_column :deferrals, :deferral_type_id, :integer
    add_index :deferrals, :deferral_type_id, name: "index_deferrals_on_deferral_type_id" unless index_exists?(:deferrals, :deferral_type_id)

    # deferrals
    change_column :deferrals, :id, :integer

    # dismissal_reasons
    remove_index :dismissals, name: "index_dismissals_on_dismissal_reason_id" if index_exists?(:dismissals, name: "index_dismissals_on_dismissal_reason_id")
    change_column :dismissal_reasons, :id, :integer
    change_column :dismissals, :dismissal_reason_id, :integer
    add_index :dismissals, :dismissal_reason_id, name: "index_dismissals_on_dismissal_reason_id" unless index_exists?(:dismissals, :dismissal_reason_id)

    # dismissals
    change_column :dismissals, :id, :integer

    # email_templates
    change_column :email_templates, :id, :integer

    # enrollment_holds
    change_column :enrollment_holds, :id, :integer

    # enrollment_statuses
    remove_index :enrollments, name: "index_enrollments_on_enrollment_status_id" if index_exists?(:enrollments, name: "index_enrollments_on_enrollment_status_id")
    change_column :enrollment_statuses, :id, :integer
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
    change_column :enrollments, :id, :integer
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
    change_column :institutions, :id, :integer
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
    change_column :levels, :id, :integer
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
    change_column :majors, :id, :integer
    change_column :student_majors, :major_id, :integer
    add_index :student_majors, :major_id, name: "index_student_majors_on_major_id" unless index_exists?(:student_majors, :major_id)

    # notification_logs
    change_column :notification_logs, :id, :integer

    # notification_params
    change_column :notification_params, :id, :integer

    # notifications
    remove_index :notification_logs, name: "index_notification_logs_on_notification_id" if index_exists?(:notification_logs, name: "index_notification_logs_on_notification_id")
    remove_index :notification_params, name: "index_notification_params_on_notification_id" if index_exists?(:notification_params, name: "index_notification_params_on_notification_id")
    change_column :notifications, :id, :integer
    change_column :notification_logs, :notification_id, :integer
    add_index :notification_logs, :notification_id, name: "index_notification_logs_on_notification_id" unless index_exists?(:notification_logs, :notification_id)
    change_column :notification_params, :notification_id, :integer
    add_index :notification_params, :notification_id, name: "index_notification_params_on_notification_id" unless index_exists?(:notification_params, :notification_id)

    # phase_completions
    change_column :phase_completions, :id, :integer

    # phase_durations
    change_column :phase_durations, :id, :integer

    # phases
    remove_index :accomplishments, name: "index_accomplishments_on_phase_id" if index_exists?(:accomplishments, name: "index_accomplishments_on_phase_id")
    remove_index :deferral_types, name: "index_deferral_types_on_phase_id" if index_exists?(:deferral_types, name: "index_deferral_types_on_phase_id")
    remove_index :phase_durations, name: "index_phase_durations_on_phase_id" if index_exists?(:phase_durations, name: "index_phase_durations_on_phase_id")
    change_column :phases, :id, :integer
    change_column :accomplishments, :phase_id, :integer
    add_index :accomplishments, :phase_id, name: "index_accomplishments_on_phase_id" unless index_exists?(:accomplishments, :phase_id)
    change_column :deferral_types, :phase_id, :integer
    add_index :deferral_types, :phase_id, name: "index_deferral_types_on_phase_id" unless index_exists?(:deferral_types, :phase_id)
    change_column :phase_durations, :phase_id, :integer
    add_index :phase_durations, :phase_id, name: "index_phase_durations_on_phase_id" unless index_exists?(:phase_durations, :phase_id)

    # professor_research_areas
    change_column :professor_research_areas, :id, :integer

    # professors
    remove_index :advisement_authorizations, name: "index_advisement_authorizations_on_professor_id" if index_exists?(:advisement_authorizations, name: "index_advisement_authorizations_on_professor_id")
    remove_index :advisements, name: "index_advisements_on_professor_id" if index_exists?(:advisements, name: "index_advisements_on_professor_id")
    remove_index :course_classes, name: "index_course_classes_on_professor_id" if index_exists?(:course_classes, name: "index_course_classes_on_professor_id")
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_professor_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_professor_id")
    remove_index :scholarships, name: "index_scholarships_on_professor_id" if index_exists?(:scholarships, name: "index_scholarships_on_professor_id")
    remove_index :thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id" if index_exists?(:thesis_defense_committee_participations, name: "index_thesis_defense_committee_participations_on_professor_id")
    change_column :professors, :id, :integer
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
    change_column :queries, :id, :integer
    change_column :query_params, :query_id, :integer
    add_index :query_params, :query_id, name: "index_query_params_on_query_id" unless index_exists?(:query_params, :query_id)

    # query_params
    remove_index :notification_params, name: "index_notification_params_on_query_param_id" if index_exists?(:notification_params, name: "index_notification_params_on_query_param_id")
    change_column :query_params, :id, :integer
    change_column :notification_params, :query_param_id, :integer
    add_index :notification_params, :query_param_id, name: "index_notification_params_on_query_param_id" unless index_exists?(:notification_params, :query_param_id)

    # report_configurations
    change_column :report_configurations, :id, :integer

    # research_areas
    remove_index :professor_research_areas, name: "index_professor_research_areas_on_research_area_id" if index_exists?(:professor_research_areas, name: "index_professor_research_areas_on_research_area_id")
    change_column :research_areas, :id, :integer
    change_column :professor_research_areas, :research_area_id, :integer
    add_index :professor_research_areas, :research_area_id, name: "index_professor_research_areas_on_research_area_id" unless index_exists?(:professor_research_areas, :research_area_id)

    # roles
    remove_index :users, name: "index_users_on_role_id" if index_exists?(:users, name: "index_users_on_role_id")
    change_column :roles, :id, :integer
    change_column :users, :role_id, :integer
    add_index :users, :role_id, name: "index_users_on_role_id" unless index_exists?(:users, :role_id)

    # scholarship_durations
    remove_index :scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id" if index_exists?(:scholarship_suspensions, name: "index_scholarship_suspensions_on_scholarship_duration_id")
    change_column :scholarship_durations, :id, :integer
    change_column :scholarship_suspensions, :scholarship_duration_id, :integer
    add_index :scholarship_suspensions, :scholarship_duration_id, name: "index_scholarship_suspensions_on_scholarship_duration_id" unless index_exists?(:scholarship_suspensions, :scholarship_duration_id)

    # scholarship_suspensions
    change_column :scholarship_suspensions, :id, :integer

    # scholarship_types
    remove_index :scholarships, name: "index_scholarships_on_scholarship_type_id" if index_exists?(:scholarships, name: "index_scholarships_on_scholarship_type_id")
    change_column :scholarship_types, :id, :integer
    change_column :scholarships, :scholarship_type_id, :integer
    add_index :scholarships, :scholarship_type_id, name: "index_scholarships_on_scholarship_type_id" unless index_exists?(:scholarships, :scholarship_type_id)

    # scholarships
    remove_index :scholarship_durations, name: "index_scholarship_durations_on_scholarship_id" if index_exists?(:scholarship_durations, name: "index_scholarship_durations_on_scholarship_id")
    change_column :scholarships, :id, :integer
    change_column :scholarship_durations, :scholarship_id, :integer
    add_index :scholarship_durations, :scholarship_id, name: "index_scholarship_durations_on_scholarship_id" unless index_exists?(:scholarship_durations, :scholarship_id)

    # sponsors
    remove_index :scholarships, name: "index_scholarships_on_sponsor_id" if index_exists?(:scholarships, name: "index_scholarships_on_sponsor_id")
    change_column :sponsors, :id, :integer
    change_column :scholarships, :sponsor_id, :integer
    add_index :scholarships, :sponsor_id, name: "index_scholarships_on_sponsor_id" unless index_exists?(:scholarships, :sponsor_id)

    # states
    remove_index :cities, name: "index_cities_on_state_id" if index_exists?(:cities, name: "index_cities_on_state_id")
    remove_index :students, name: "index_students_on_birth_state_id" if index_exists?(:students, name: "index_students_on_birth_state_id")
    change_column :states, :id, :integer
    change_column :cities, :state_id, :integer
    add_index :cities, :state_id, name: "index_cities_on_state_id" unless index_exists?(:cities, :state_id)
    change_column :students, :birth_state_id, :integer
    add_index :students, :birth_state_id, name: "index_students_on_state_id" unless index_exists?(:students, :birth_state_id)

    # student_majors
    change_column :student_majors, :id, :integer

    # students
    remove_index :enrollments, name: "index_enrollments_on_student_id" if index_exists?(:enrollments, name: "index_enrollments_on_student_id")
    remove_index :student_majors, name: "index_student_majors_on_student_id" if index_exists?(:student_majors, name: "index_student_majors_on_student_id")
    change_column :students, :id, :integer
    change_column :enrollments, :student_id, :integer
    add_index :enrollments, :student_id, name: "index_enrollments_on_student_id" unless index_exists?(:enrollments, :student_id)
    change_column :student_majors, :student_id, :integer
    add_index :student_majors, :student_id, name: "index_student_majors_on_student_id" unless index_exists?(:student_majors, :student_id)

    # thesis_defense_committee_participations
    change_column :thesis_defense_committee_participations, :id, :integer

    # users
    remove_index :professors, name: "index_professors_on_user_id" if index_exists?(:professors, name: "index_professors_on_user_id")
    remove_index :students, name: "index_students_on_user_id" if index_exists?(:students, name: "index_students_on_user_id")
    remove_index :users, name: "index_users_on_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_id")
    remove_index :users, name: "index_users_on_invited_by_type_and_invited_by_id" if index_exists?(:users, name: "index_users_on_invited_by_type_and_invited_by_id")
    change_column :users, :id, :integer
    change_column :professors, :user_id, :integer
    add_index :professors, :user_id, name: "index_professors_on_user_id" unless index_exists?(:professors, :user_id)
    change_column :users, :invited_by_id, :integer
    add_index :users, :invited_by_id, name: "index_users_on_invited_by_id" unless index_exists?(:users, :invited_by_id)
    change_column :users, :invited_by_id, :integer
    add_index :users, [:invited_by_type, :invited_by_id], name: "index_users_on_invited_by_type_and_invited_by_id" unless index_exists?(:users, [:invited_by_type, :invited_by_id])

    # versions
    change_column :versions, :id, :integer


    change_column :versions, :item_id, :integer
    add_index :versions, [:item_type, :item_id] unless index_exists?(:versions, [:item_type, :item_id])
    add_reference :students, :user, foreign_key: { on_delete: :nullify }
    Student.update_all("user_id = temp_user_id")
    remove_column :students, :temp_user_id
  end
end