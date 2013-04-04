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
    primary.item :stud, 'Alunos', enrollments_path do |stud|
      stud.item :student, 'Alunos', students_path
      stud.item :dismissal, 'Desligamentos', dismissals_path
      stud.item :enrollment, 'Matrículas', enrollments_path
      stud.item :level, 'Níveis', levels_path
      stud.item :dismissal_reason, 'Razões de Desligamento', dismissal_reasons_path
      stud.item :enrollment_status, 'Tipos de Matrícula', enrollment_statuses_path
    end

    primary.item :prof, 'Professores', professors_path do |prof|
      prof.item :professor, 'Professores', professors_path     
      prof.item :advisement, 'Orientações', advisements_path
      prof.item :advisement_authorizations, 'Credenciamentos', advisement_authorizations_path
    end

    primary.item :scholarships, 'Bolsas', scholarship_durations_path do |scholarships|
      scholarships.item :sponsor, 'Agências de Fomento', sponsors_path
      scholarships.item :scholarship_duration, 'Alocação de Bolsas', scholarship_durations_path
      scholarships.item :scholarship, 'Bolsas', scholarships_path
      scholarships.item :scholarship_type, 'Tipos de Bolsa', scholarship_types_path
    end

    primary.item :phases, 'Etapas', phases_path do |phases|
      phases.item :deferral, 'Prorrogações Concedidas', deferrals_path
      phases.item :accomplishment, 'Realizações de Etapas', accomplishments_path
      phases.item :phase, 'Tipos de Etapas', phases_path
      phases.item :deferral_type, 'Tipos de Prorrogação', deferral_types_path
    end

    primary.item :courses, 'Disciplinas',courses_path do |courses|
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

    primary.item :locations, 'Localidades', cities_path do |locations|
      locations.item :city, 'Cidades', cities_path
      locations.item :state, 'Estados', states_path
      locations.item :country, 'Países', countries_path
    end

    primary.item :configuration, 'Configurações', users_path do |configuration|
      configuration.item :user, 'Usuários', users_path
    end

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