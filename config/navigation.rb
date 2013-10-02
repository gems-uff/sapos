# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  # navigation.selected_class = 'selected'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  # navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  # navigation.name_generator = Proc.new {|name| "<span>#{name}</span>"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  # navigation.auto_highlight = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>:if => Proc.new { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>:unless => Proc.new { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.
    #

    def get_path_from(models)
      models = models.is_a?(Array) ? models : [models]
      models.each do |model|
        if can_read?(model, false)
          return self.send("#{model.name.underscore.pluralize.downcase}_path")
        end
      end
    end

    def can_read?(models, proc = true)
      can_read = false
      models = models.is_a?(Array) ? models : [models]
      models.each do |model|
        can_read ||= can?(:read, model)
      end
      return can_read ? Proc.new { true } : Proc.new { false } if proc
      can_read
    end

    alunos_models = [Student, Dismissal, Enrollment, Level, DismissalReason, EnrollmentStatus]

    primary.item :stud, 'Alunos', get_path_from(alunos_models), :if => can_read?(alunos_models) do |stud|
      stud.item :student, 'Alunos', students_path, :if => can_read?(Student)
      stud.item :dismissal, 'Desligamentos', dismissals_path, :if => can_read?(Dismissal)
      stud.item :enrollment, 'Matrículas', enrollments_path, :if => can_read?(Enrollment)
      stud.item :level, 'Níveis', levels_path, :if => can_read?(Level)
      stud.item :dismissal_reason, 'Razões de Desligamento', dismissal_reasons_path, :if => can_read?(DismissalReason)
      stud.item :enrollment_status, 'Tipos de Matrícula', enrollment_statuses_path, :if => can_read?(EnrollmentStatus)
    end


    professores_models = [Professor, Advisement, AdvisementAuthorization]
    primary.item :prof, 'Professores', get_path_from(professores_models), :if => can_read?(professores_models) do |prof|
      prof.item :professor, 'Professores', professors_path, :if => can_read?(Professor)
      prof.item :advisement, 'Orientações', advisements_path, :if => can_read?(Advisement)
      prof.item :advisement_authorizations, 'Credenciamentos', advisement_authorizations_path, :if => can_read?(AdvisementAuthorization)
    end

    bolsas_models = [Scholarship, ScholarshipType, ScholarshipDuration]
    primary.item :scholarships, 'Bolsas', get_path_from(bolsas_models), :if => can_read?(bolsas_models) do |scholarships|
      scholarships.item :sponsor, 'Agências de Fomento', sponsors_path, :if => can_read?(Sponsor)
      scholarships.item :scholarship_duration, 'Alocação de Bolsas', scholarship_durations_path, :if => can_read?(ScholarshipDuration)
      scholarships.item :scholarship, 'Bolsas', scholarships_path, :if => can_read?(Scholarship)
      scholarships.item :scholarship_type, 'Tipos de Bolsa', scholarship_types_path, :if => can_read?(ScholarshipType)
    end

    etapas_models = [Deferral, Accomplishment, Phase, DeferralType]
    primary.item :phases, 'Etapas', get_path_from(etapas_models), :if => can_read?(etapas_models) do |phases|
      phases.item :deferral, 'Prorrogações Concedidas', deferrals_path, :if => can_read?(Deferral)
      phases.item :accomplishment, 'Realizações de Etapas', accomplishments_path, :if => can_read?(Accomplishment)
      phases.item :phase, 'Tipos de Etapas', phases_path, :if => can_read?(Phase)
      phases.item :deferral_type, 'Tipos de Prorrogação', deferral_types_path, :if => can_read?(DeferralType)
    end

    primary.item :courses, 'Disciplinas', courses_path do |courses|
      courses.item :research_area, 'Áreas de Pesquisa', research_areas_path
      courses.item :course, 'Disciplinas', courses_path
      courses.item :course_type, 'Tipos de Disciplinas', course_types_path
      courses.item :course_class, 'Turmas', course_classes_path
      courses.item :class_enrollment, 'Inscrições', class_enrollments_path
      courses.item :allocation, 'Alocações', allocations_path
    end

    primary.item :grade, 'Formação', majors_path do |grade|
      grade.item :major, 'Cursos', majors_path
      grade.item :institution, 'Instituições', institutions_path
    end

    localidades_models = [City, State, Country]
    primary.item :locations, 'Localidades', get_path_from(localidades_models), :if => can_read?(localidades_models) do |locations|
      locations.item :city, 'Cidades', cities_path, :if => can_read?(City)
      locations.item :state, 'Estados', states_path, :if => can_read?(State)
      locations.item :country, 'Países', countries_path, :if => can_read?(Country)
    end

    configuracoes_models = [User, Role, Configuration]
    primary.item :configuration, 'Configurações', get_path_from(configuracoes_models), :if => can_read?(configuracoes_models) do |configuration|
      configuration.item :user, 'Usuários', users_path, :if => can_read?(User)
      configuration.item :roles, 'Papéis', roles_path, :if => can_read?(Role)
      configuration.item :configuration, 'Configurações', configurations_path, :if => can_read?(Configuration)
    end

    primary.item :logout, 'Logout', destroy_user_session_path

    # Add an item which has a sub navigation (same params, but with block)
    #primary.item :key_2, 'name', url, options do |sub_nav|
    # Add an item to the sub navigation (same params again)
    #  sub_nav.item :key_2_1, 'name', url, options
    #end

    # You can also specify a condition-proc that needs to be fullfilled to display an item.
    # Conditions are part of the options. They are evaluated in the context of the views,
    # thus you can use all the methods and vars you have available in the views.
    #primary.item :key_3, 'Admin', url, :class => 'special', :if => Proc.new { current_user.admin? }
    #primary.item :key_4, 'Account', url, :unless => Proc.new { logged_in? }

    # you can also specify a css id or class to attach to this particular level
    # works for all levels of the menu
    # primary.dom_id = 'menu-id'
    # primary.dom_class = 'menu-class'

    # You can turn off auto highlighting for a specific level
    # primary.auto_highlight = false

  end

end