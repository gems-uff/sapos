# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

def get_path_from(models)
  models = models.is_a?(Array) ? models : [models]
  models.each do |model|
    if can_read?(model, false)
      return self.send("#{model.name.demodulize.underscore.pluralize.downcase}_path")
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

class NavigationHelper
  attr_accessor :container, :parentkey, :binds

  def initialize(binds, container, options = {})
    @binds = binds
    @container = container
    @parentkey = options.fetch(:parentkey, nil)
  end

  # Add an item to the primary navigation. The following params apply:
  # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
  #       in the mainitem.call, key will be used to produce the I18n name: navigation.{key}.label
  #       in the submenu.item, key will be used to produce the I18n name: navigation.{parentkey}.{key}
  # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
  # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
  #           some special options that can be set:
  #           :if - Specifies a proc to call to determine if the item should
  #                 be rendered (e.g. <tt>if: Proc.new { current_user.admin? }</tt>). The
  #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
  #           :unless - Specifies a proc to call to determine if the item should not
  #                     be rendered (e.g. <tt>unless: Proc.new { current_user.admin? }</tt>). The
  #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
  #           :method - Specifies the http-method for the generated link - default is :get.
  #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
  #                            when the item should be highlighted, you can set a regexp which is matched
  #                            against the current URI.
  #
  def item(key, url, options = {})
    parentkey = @parentkey || key
    childi18n = @parentkey.nil? ? :label : key

    @container.item(
      key, I18n.t("navigation.#{parentkey}.#{childi18n}"), url, **options
    ) do |item_container|
      yield NavigationHelper.new(
        @binds, item_container, parentkey: key
      ) if block_given?
    end
  end

  # Create item for a list of models.
  # Use the first one the user can read to create the url
  def listitem(key, models, options = {}, &block)
    options[:if] ||= can_read?(models)
    url = get_path_from(models)
    item(key, url, options, &block)
  end

  # Create item for a model if the user has read permission
  # Use the singular name of the model to create the key
  def modelitem(model, options = {}, &block)
    key = model.name.demodulize.underscore.singularize.downcase
    listitem(key, model, options, &block)
  end

  protected
    def get_path_from(*args)
      @binds.eval("method(:get_path_from)").call(*args)
    end

    def can_read?(*args)
      @binds.eval("method(:can_read?)").call(*args)
    end
end


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
    mainhelper = NavigationHelper.new(binding, primary)

    mainhelper.item :main, landing_url, if: can_read?(:landing) do |submenu|
      submenu.item :pendencies, pendencies_url, if: can_read?(:pendency)
      @landingsidebar.call(submenu.container)
      submenu.item(
        :profile, edit_user_registration_path,
        highlights_on: %r(/users/profile), if: -> { user_signed_in? }
      )
    end

    students_models = [
      Enrollment, Dismissal, Student, EnrollmentHold, Level,
      DismissalReason, EnrollmentStatus
    ]
    mainhelper.listitem :students, students_models do |submenu|
      submenu.modelitem Student
      submenu.modelitem Dismissal
      submenu.modelitem Enrollment
      submenu.modelitem EnrollmentHold
      submenu.modelitem Level
      submenu.modelitem DismissalReason
      submenu.modelitem EnrollmentStatus
    end

    professors_models = [Professor, Advisement, AdvisementAuthorization]
    mainhelper.listitem :professors, professors_models do |submenu|
      submenu.modelitem Professor
      submenu.modelitem Advisement
      submenu.modelitem AdvisementAuthorization
      submenu.modelitem ThesisDefenseCommitteeParticipation
    end

    scholar_models = [Scholarship, ScholarshipType, ScholarshipDuration]
    mainhelper.listitem :scholarships, scholar_models do |submenu|
      submenu.modelitem Sponsor
      submenu.modelitem ScholarshipDuration
      submenu.modelitem Scholarship
      submenu.modelitem ScholarshipType
    end

    phases_models = [Deferral, Accomplishment, Phase, DeferralType]
    mainhelper.listitem :phases, phases_models do |submenu|
      submenu.modelitem Deferral
      submenu.modelitem Accomplishment
      submenu.modelitem Phase
      submenu.modelitem DeferralType
    end

    courses_models = [
      Course, ResearchArea, CourseType, CourseClass, ClassSchedule,
      ClassEnrollment, Allocation, EnrollmentRequest, ClassEnrollmentRequest
    ]
    mainhelper.listitem :courses, courses_models do |submenu|
      submenu.modelitem ResearchArea
      submenu.modelitem Course
      submenu.modelitem CourseType
      submenu.modelitem CourseClass
      submenu.modelitem ClassSchedule
      submenu.modelitem ClassEnrollment
      submenu.modelitem Allocation
      submenu.modelitem EnrollmentRequest
      submenu.modelitem ClassEnrollmentRequest
    end

    grade_models = [Major, Institution]
    mainhelper.listitem :grades, grade_models do |submenu|
      submenu.modelitem Major
      submenu.modelitem Institution
    end

    locations_models = [City, State, Country]
    mainhelper.listitem :locations, locations_models do |submenu|
      submenu.modelitem City
      submenu.modelitem State
      submenu.modelitem Country
    end

    admission_models = [
      Admissions::AdmissionProcess,
      Admissions::FormTemplate,
      Admissions::AdmissionCommittee,
      Admissions::AdmissionPhase,
      Admissions::AdmissionApplication,
    ]
    mainhelper.listitem :admissions, admission_models do |submenu|
      submenu.modelitem Admissions::AdmissionProcess
      submenu.modelitem Admissions::FormTemplate
      submenu.item(:consolidation_template, consolidation_templates_path,
        if: can_read?([Admissions::FormTemplate]))
      submenu.modelitem Admissions::AdmissionCommittee
      submenu.modelitem Admissions::AdmissionPhase
      submenu.modelitem Admissions::AdmissionApplication
    end

    config_models = [
      User, Role, CustomVariable, Version, Notification,
      NotificationLog, ReportConfiguration, EmailTemplate
    ]
    mainhelper.listitem :configurations, config_models do |submenu|
      submenu.modelitem User
      submenu.modelitem Role
      submenu.modelitem Version
      submenu.modelitem Notification
      submenu.modelitem EmailTemplate
      submenu.modelitem Query
      submenu.modelitem NotificationLog
      submenu.modelitem CustomVariable
      submenu.modelitem ReportConfiguration
    end

    mainhelper.item :logout, destroy_user_session_path

    # Add an item which has a sub navigation (same params, but with block)
    # primary.item :key_2, 'name', url, options do |sub_nav|
    # Add an item to the sub navigation (same params again)
    #  sub_nav.item :key_2_1, 'name', url, options
    # end

    # You can also specify a condition-proc that needs to be fullfilled to display an item.
    # Conditions are part of the options. They are evaluated in the context of the views,
    # thus you can use all the methods and vars you have available in the views.
    # primary.item :key_3, 'Admin', url, class: 'special', if: Proc.new { current_user.admin? }
    # primary.item :key_4, 'Account', url, unless: Proc.new { logged_in? }

    # you can also specify a css id or class to attach to this particular level
    # works for all levels of the menu
    # primary.dom_id = 'menu-id'
    # primary.dom_class = 'menu-class'

    # You can turn off auto highlighting for a specific level
    # primary.auto_highlight = false
  end
end
