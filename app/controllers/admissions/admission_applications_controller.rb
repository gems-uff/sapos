# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionApplicationsController < ApplicationController
  authorize_resource
  before_action :update_table_config

  I18N_BASE = "activerecord.attributes.admissions/admission_application"

  active_scaffold "Admissions::AdmissionApplication" do |config|
    config.list.columns = [
      :admission_process, :token, :name, :email, :submission_time,
      :letter_requests, :filled_form,
      :admission_phase, :status
    ]
    config.show.columns = [
      :admission_process, :token, :name, :email,
      :admission_phase, :status,
      :filled_form, :letter_requests,
      :results, :evaluations, :rankings
    ]

    config.list.sorting = { admission_process: "DESC", name: "ASC" }

    config.delete.link.weight = -1
    config.delete.link.html_options = { class: "advanced-config-item" }

    config.action_links.add "cancel",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_application.cancel.title"
      }' class='fa fa-remove'></i>".html_safe,
      type: :member,
      keep_open: false,
      position: false,
      crud_type: :update,
      method: :put,
      html_options: { class: "advanced-config-item" },
      refresh_list: true,
      ignore_method: :cancel_ignore?,
      security_method: :cancel_authorized?,
      confirm: I18n.t(
        "active_scaffold.admissions/admission_application.cancel.confirm"
      )

    config.action_links.add "undo_consolidation",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_application.undo_consolidation.title"
      }' class='fa fa-undo'></i>".html_safe,
      type: :member,
      keep_open: false,
      position: false,
      crud_type: :update,
      method: :put,
      html_options: { class: "advanced-config-item" },
      refresh_list: true,
      ignore_method: :undo_consolidation_ignore?,
      security_method: :undo_consolidation_authorized?,
      confirm: I18n.t(
        "active_scaffold.admissions/admission_application.undo_consolidation.confirm"
      )

    config.action_links.add "edit_override",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_application.edit_override.title"
      }' class='fa fa-pencil-square edit-override'></i>".html_safe,
      type: :member,
      ignore_method: :override_ignore?,
      security_method: :override_authorized?,
      html_options: { class: "advanced-config-item" },
      action: :edit,
      parameters: {
        override: true
      }

    config.action_links.add "configuration",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_application.configuration.title"
      }' class='fa fa-cog advanced-config'></i>".html_safe,
      type: :member,
      security_method: :configuration_authorized?,
      ignore_method: :configuration_ignore?,
      position: false

    config.action_links.add "configure_all",
      label: I18n.t("active_scaffold.admissions/admission_application.configure_all.title"),
      type: :collection,
      security_method: :configure_all_authorized?,
      ignore_method: :configure_all_ignore?,
      position: false

    config.action_links.add "map_student_form",
      label: "<i title='#{
        I18n.t "active_scaffold.admissions/admission_application.map_student_form.title"
      }' class='fa fa-user-o'></i>".html_safe,
      type: :member,
      security_method: :map_student_form_authorized?,
      ignore_method: :map_student_form_ignore?

    config.columns.add :is_filled
    config.columns.add :pendency
    config.columns.add :custom_forms

    config.columns[:admission_process].search_ui = :record_select
    config.columns[:is_filled].search_sql = ""
    config.columns[:is_filled].search_ui = :select
    config.columns[:is_filled].options = {
      options: I18n.t("#{I18N_BASE}.is_filled_options").values,
      include_blank: I18n.t("active_scaffold._select_")
    }
    config.columns[:pendency].search_sql = ""
    config.columns[:pendency].search_ui = :select
    config.columns[:pendency].options = {
      options: I18n.t("#{I18N_BASE}.pendency_options").values,
      include_blank: I18n.t("active_scaffold._select_")
    }
    config.columns[:admission_phase].actions_for_association_links = [:show]
    config.columns[:admission_phase].search_ui = :record_select
    config.columns[:admission_phase].sort_by sql: [:admission_phase_id]

    config.columns[:status].search_sql = ""
    config.columns[:status].search_ui = :select

    config.update.columns = [:custom_forms]
    config.update.multipart = true


    config.actions.swap :search, :field_search
    config.field_search.columns = [
      :admission_process,
      :token,
      :name,
      :email,
      :is_filled,
      :pendency,
      :admission_phase,
      :status
    ]
    config.actions.exclude :deleted_records, :create
  end

  def update_table_config
    if current_user
      active_scaffold_config.columns[:status].sort_by sql: Arel.sql("
        CASE
          WHEN `admission_applications`.`status` IS NOT NULL THEN `admission_applications`.`status`
          WHEN `admission_applications`.`id` IN (
            SELECT `admission_application_id`
            FROM `admission_pendencies`
            WHERE `admission_pendencies`.`status`=\"#{Admissions::AdmissionPendency::PENDENT}\"
            AND (
              (
                `admission_pendencies`.`admission_phase_id` IS NULL AND
                `admission_applications`.`admission_phase_id` IS NULL
              ) OR (
                `admission_pendencies`.`admission_phase_id` = `admission_applications`.`admission_phase_id`
              )
            )
            AND `admission_pendencies`.`user_id`=#{current_user.id}
          ) THEN \"#{Admissions::AdmissionPendency::PENDENT}\"
          ELSE \"-\"
        END
      ")
    else
      active_scaffold_config.columns[:status].sort_by sql: "status"
    end
  end

  def self.condition_for_is_filled_column(column, value, like_pattern)
    filled_form = "
      select `ff`.`id` from filled_forms `ff`
      where `ff`.`is_filled` = 1
    "
    case value
    when I18n.t("#{I18N_BASE}.is_filled_options.true")
      ["`admission_applications`.`filled_form_id` in (#{filled_form})"]
    when I18n.t("#{I18N_BASE}.is_filled_options.false")
      ["`admission_applications`.`filled_form_id` not in (#{filled_form})"]
    else
      ""
    end
  end

  def self.condition_for_pendency_column(column, value, like_pattern)
    candidate_arel = Admissions::AdmissionApplication.arel_table
    pendency_arel = Admissions::AdmissionPendency.arel_table
    pendencies_query = pendency_arel.where(
      pendency_arel[:status].eq(Admissions::AdmissionPendency::PENDENT)
      .and(pendency_arel[:admission_phase_id].eq(candidate_arel[:admission_phase_id]))
    ).project(pendency_arel[:admission_application_id])
    case value
    when I18n.t("#{I18N_BASE}.pendency_options.true")
      [candidate_arel[:id].in(pendencies_query).to_sql]
    when I18n.t("#{I18N_BASE}.pendency_options.false")
      [candidate_arel[:id].not_in(pendencies_query).to_sql]
    else
      ""
    end
  end

  def self.condition_for_status_column(column, value, like_pattern)
    candidate_arel = Admissions::AdmissionApplication.arel_table
    return "" if value.blank?
    if value.to_i.to_s == value
      value = value.to_i
      user_id = value.abs
      pendency_arel = Admissions::AdmissionPendency.arel_table
      pendencies_query = pendency_arel.where(
        pendency_arel[:status].eq(Admissions::AdmissionPendency::PENDENT)
        .and(pendency_arel[:admission_phase_id].eq(candidate_arel[:admission_phase_id]))
        .and(pendency_arel[:user_id].eq(user_id))
      ).project(pendency_arel[:admission_application_id])
      result = candidate_arel[:status].eq(nil)
      if value < 0
        [result.and(candidate_arel[:id].not_in(pendencies_query)).to_sql]
      else
        [result.and(candidate_arel[:id].in(pendencies_query)).to_sql]
      end
    else
      [candidate_arel[:status].eq(value).to_sql]
    end
  end

  def update_authorized?(record = nil, column = nil)
    return super if record.nil?
    phase = record.admission_phase
    return false if phase.nil?
    return false if Admissions::AdmissionApplication::END_OF_PHASE_STATUSES.include?(
      record.status
    )

    phase.admission_committees.any? do |committee|
      if record.satisfies_condition(committee.form_condition)
        committee.members.where(user_id: current_user.id).first.present?
      end
    end && super
  end

  def cancel_ignore?(record)
    (
      (record.status == Admissions::AdmissionApplication::CANCELED) ||
      cannot?(:cancel, record)
    )
  end

  def cancel_authorized?(record = nil, column = nil)
    can?(:cancel, record)
  end

  def cancel
    raise CanCan::AccessDenied.new if cannot? :cancel, Admissions::AdmissionApplication
    process_action_link_action(:cancel) do |record|
      next if cancel_ignore?(record)
      record.update!(
        status: Admissions::AdmissionApplication::CANCELED,
        status_message: nil,
      )
      self.successful = true
      flash[:info] = I18n.t("active_scaffold.admissions/admission_application.cancel.success")
    end
  end

  def undo_consolidation_ignore?(record)
    eop = Admissions::AdmissionApplication::END_OF_PHASE_STATUSES
    (record.admission_phase_id.nil? && !eop.include?(record.status)) ||
      cannot?(:undo_consolidation, record) ||
      !record.admission_process.staff_can_undo
  end

  def undo_consolidation_authorized?(record = nil, column = nil)
    can?(:undo_consolidation, record)
  end

  def undo_consolidation
    raise CanCan::AccessDenied.new if cannot? :undo_consolidation, Admissions::AdmissionApplication
    process_action_link_action(:undo_consolidation) do |record|
      next if undo_consolidation_ignore?(record)
      eop = Admissions::AdmissionApplication::END_OF_PHASE_STATUSES
      if eop.include?(record.status)
        set_phase_id = record.admission_phase_id
      else
        phases = [nil] + record.admission_process.phases.order(:order).map do |p|
          p.admission_phase.id
        end
        index = phases.find_index(record.admission_phase_id)
        set_phase_id = phases[index - 1]
      end
      record.pendencies.where(
        status: Admissions::AdmissionPendency::PENDENT,
        admission_phase_id: record.admission_phase_id
      ).delete_all
      record.update!(
        admission_phase_id: set_phase_id,
        status: nil,
        status_message: nil,
      )
      if set_phase_id.present?
        record.results.where(
          mode: Admissions::AdmissionPhaseResult::CONSOLIDATION,
          admission_phase_id: set_phase_id
        ).delete_all
        prev_phase = Admissions::AdmissionPhase.find(set_phase_id)
        prev_phase.update_pendencies
        prev_phase_name = prev_phase.name
      else
        prev_phase_name = "Candidatura"
      end
      self.successful = true
      flash[:info] = I18n.t("active_scaffold.admissions/admission_application.undo_consolidation.success", name: prev_phase_name)
    end
  end

  def override_authorized?(record = nil, column = nil)
    return super if record.nil?
    can?(:override, record) && record.admission_process.staff_can_edit
  end

  def override_ignore?(record)
    cannot?(:override, record) || !record.admission_process.staff_can_edit
  end

  def configuration_ignore?(record)
    !(
      !cannot?(:destroy, record) ||
      !cancel_ignore?(record) ||
      !undo_consolidation_ignore?(record) ||
      !override_ignore?(record)
    )
  end

  def configuration_authorized?(record = nil, column = nil)
    can?(:destroy, record) ||
    cancel_authorized?(record) ||
    undo_consolidation_authorized?(record) ||
    override_authorized?(record)
  end

  def configuration
    @record = find_if_allowed(params[:id], :read)
  end

  def configure_all_ignore?
    !(
      !cannot?(:destroy, Admissions::AdmissionApplication) ||
      !cannot?(:cancel, Admissions::AdmissionApplication) ||
      !cannot?(:undo, Admissions::AdmissionApplication) ||
      !cannot?(:override, Admissions::AdmissionApplication)
    )
  end

  def configure_all_authorized?(record = nil, column = nil)
    can?(:destroy, record || Admissions::AdmissionApplication) ||
    can?(:cancel, record || Admissions::AdmissionApplication) ||
    can?(:undo, record || Admissions::AdmissionApplication) ||
    can?(:override, record || Admissions::AdmissionApplication)
  end

  def configure_all
    respond_to_action(:configure_all)
  end

  def map_student_form_authorized?(record = nil, column = nil)
    return super if record.nil?
    can?(:map_student, record)
  end

  def map_student_form_ignore?(record)
    cannot?(:map_student, record)
  end

  def map_student_form
    do_map_student_form
    respond_to_action(:map_student_form)
  end

  def map_student_form_create_update
    do_map_student_form_create_update
    respond_to_action(:map_student_form_create_update)
  end

  protected
    def do_map_student_form(options = {})
      @do_not_create_enrollment ||= params[:do_not_create_enrollment]
      @record = @admission_application = find_if_allowed(params[:id], :map_student)
      @student ||= @admission_application.student
      @enrollment ||= @admission_application.enrollment

      @student_operation = :new
      @enrollment_operation = :new
      @student_operation = :edit if @admission_application.student.present?
      @enrollment_operation = :edit if @admission_application.enrollment.present?

      @creating_student = false
      @creating_enrollment = false
      if @student.nil?
        find_student = Student.find_by(id: params[:student_id])
        if find_student.present?
          @student_operation = :link
          @student = find_student
        else
          @student = Student.new
          @creating_student = true
        end
      end
      if @enrollment.nil?
        @enrollment = Enrollment.new
        @creating_enrollment = true
      end

      if !options[:do_not_set_attributes]
        field_objects = @admission_application.fields_hash
        if @student_operation != :edit
          @admission_application.update_student(@student, field_objects:)
          apply_constraints_to_record(@student)
          # create_association_with_parent(@record) if nested?
        end
        if @enrollment_operation != :edit
          process = @admission_application.admission_process
          @enrollment = Enrollment.new
          @creating_enrollment = true
          @enrollment.student = @student
          @enrollment.level = process.level
          @enrollment.enrollment_status = process.enrollment_status
          @enrollment.admission_date = process.admission_date
          if process.enrollment_number_field.present?
            filled_field = field_objects[process.enrollment_number_field]
            raise Exceptions::MissingFieldException.new(
              "Campo de Formulário não encontrado: #{process.enrollment_number_field}"
            ) if filled_field.blank?
            @enrollment.enrollment_number = filled_field.simple_value
          end
          apply_constraints_to_record(@enrollment)
        end
      else
        if @student_operation != :edit && !params[:record_student][:photo].present?
          @admission_application.update_student(@student, only_photo: true)
        end
      end
      @original_student = @student
      @original_enrollment = @enrollment
    ensure
      # Prevent param propagation in params_for helper
      params.delete :student_id if params.include? :student_id
      params.delete :do_not_create_enrollment if params.include? :do_not_create_enrollment
    end

    def do_map_student_form_create_update
      # Based on do_create and do_update
      # https://github.com/activescaffold/active_scaffold/blob/51e9ff6a29ec538455e2120665e075c7ff087c11/lib/active_scaffold/actions/create.rb#L93
      # https://github.com/activescaffold/active_scaffold/blob/51e9ff6a29ec538455e2120665e075c7ff087c11/lib/active_scaffold/actions/update.rb#L106
      do_map_student_form(do_not_set_attributes: true)
      student_controller = StudentsController.new
      enrollment_controller = EnrollmentsController.new
      ActiveRecord::Base.transaction do
        self.successful = true
        @student = update_record_from_params(
          @student,
          StudentsController.active_scaffold_config.create.columns,
          params[:record_student]
        )
        if @creating_student
          apply_constraints_to_record(@student, allow_autosave: true)
          # create_association_with_parent(@record) if nested?
          student_controller.send(:before_create_save, @student)
        else
          student_controller.send(:before_update_save, @student)
        end
        # errors to @record can be added by update_record_from_params when association fails
        # to set and ActiveRecord::RecordNotSaved is raised
        # this syntax avoids a short-circuit, so we run validations on record and associations
        self.successful = successful? || [
          @student.keeping_errors { @student.valid? },
          @student.associated_valid?
        ].all? # this syntax avoids a short-circuit

        if !@do_not_create_enrollment
          @enrollment = update_record_from_params(
            @enrollment,
            EnrollmentsController.active_scaffold_config.create.columns,
            params[:record_enrollment]
          )
          @enrollment.student = @student
          if @creating_enrollment
            apply_constraints_to_record(@enrollment, allow_autosave: true)
            # create_association_with_parent(@record) if nested?
            enrollment_controller.send(:before_create_save, @enrollment)
          else
            enrollment_controller.send(:before_update_save, @enrollment)
          end
          self.successful = successful? || [
            @enrollment.keeping_errors { @enrollment.valid? },
            @enrollment.associated_valid?
          ].all? # this syntax avoids a short-circuit
        end

        unless successful?
          # some associations such as habtm are saved before saved is called on parent object
          # we have to revert these changes if validation fails
          raise ActiveRecord::Rollback, "don't save habtm associations unless record is valid"
        end
        @admission_application.student = @student
        @student.save! && @student.save_associated!
        if !@do_not_create_enrollment
          @admission_application.enrollment = @enrollment
          @enrollment.save! && @enrollment.save_associated!
        end
        @admission_application.save!

        if @creating_student
          student_controller.send(:after_create_save, @student)
        else
          student_controller.send(:after_update_save, @student)
        end
        if !@do_not_create_enrollment
          if @creating_enrollment
            enrollment_controller.send(:after_create_save, @enrollment)
          else
            enrollment_controller.send(:after_update_save, @enrollment)
          end
        end
      end
    rescue ActiveRecord::StaleObjectError
      @student = @original_student
      @enrollment = @original_enrollment
      @student.errors.add(:base, as_(:version_inconsistency))
      self.successful = false
    rescue ActiveRecord::RecordNotSaved => exception
      @student = @original_student
      @enrollment = @original_enrollment
      logger.warn do
        "\n\n#{exception.class} (#{exception.message}):\n    " +
          Rails.backtrace_cleaner.clean(exception.backtrace).join("\n    ") +
          "\n\n"
      end
      @student.errors.add(:base, as_(:record_not_saved)) if @student.errors.empty?
      self.successful = false
    rescue ActiveRecord::ActiveRecordError => ex
      flash[:error] = ex.message
      self.successful = false
      @student = @original_student
      @enrollment = @original_enrollment
    ensure
      # Prevent param propagation in params_for helper
      params.delete :record_enrollment if params.include? :record_enrollment
      params.delete :record_student if params.include? :record_student
    end

    def before_update_save(record)
      record.filled_form.prepare_missing_fields
      phase = record.admission_phase
      record.assign_attributes(admission_application_params)
      record.letter_requests.each do |letter_request|
        letter_request.filled_form.sync_fields_after(letter_request)
      end
      if phase.present?
        phase_forms = phase.prepare_application_forms(record, current_user, false)
        phase_forms.each do |phase_form|
          phase_form[:was_filled] = phase_form[:object].filled_form.is_filled
          phase_form[:object].filled_form.is_filled = true
        end
      else
        phase_forms = []
      end
      record.filled_form.sync_fields_after(record)
      was_filled = record.filled_form.is_filled
      record.filled_form.is_filled = true
      if record.valid?
        phase_forms.each do |phase_form|
          pendency_success = phase_form[:pendency_success]
          if pendency_success.present?
            Admissions::AdmissionPendency.where(pendency_success).update_all(
              status: Admissions::AdmissionPendency::OK
            )
          end
        end
      else
        record.filled_form.is_filled = was_filled
        phase_forms.each do |phase_form|
          phase_form[:object].filled_form.is_filled = phase_form[:was_filled]
        end
      end
    end

    def admission_application_params
      params.require(:record).permit(
        :name, :email,
        filled_form_attributes:
          Admissions::FilledFormsController.filled_form_params_definition,
        letter_requests_attributes: [
          :id, :email, :name, :telephone,
          :_destroy,
          filled_form_attributes:
            Admissions::FilledFormsController.filled_form_params_definition,
        ],
        results_attributes: [
          :id, :mode, :admission_phase_id,
          filled_form_attributes:
            Admissions::FilledFormsController.filled_form_params_definition,
        ],
        evaluations_attributes: [
          :id, :user_id, :admission_phase_id,
          filled_form_attributes:
            Admissions::FilledFormsController.filled_form_params_definition,
        ]
      )
    end

    def undo_consolidation_respond_to_html
      return_to_main
    end

    def undo_consolidation_respond_to_js
      do_refresh_list if !render_parent?
      @popstate = true
      render(action: "on_undo_consolidation")
    end

    def undo_consolidation_respond_on_iframe
      do_refresh_list if !render_parent?
      responds_to_parent do
        render action: "on_undo_consolidation", formats: [:js], layout: false
      end
    end

    def cancel_respond_to_html
      return_to_main
    end

    def cancel_respond_to_js
      do_refresh_list if !render_parent?
      @popstate = true
      render(action: "on_cancel")
    end

    def cancel_respond_on_iframe
      do_refresh_list if !render_parent?
      responds_to_parent do
        render action: "on_cancel", formats: [:js], layout: false
      end
    end

    def configure_all_respond_to_js
      do_refresh_list if !render_parent?
      @popstate = true
      render(action: "configure_all")
    end

    def map_student_form_respond_to_html
      if successful?
        render(action: "map_student_form_create_update")
      else
        return_to_main
      end
    end

    def map_student_form_respond_to_js
      render(partial: "map_student_form_create_update_form")
    end

    def map_student_form_create_update_respond_on_iframe
      # do_refresh_list if successful? && !render_parent?
      responds_to_parent do
        render action: "on_map_student_form_create_update", formats: [:js], layout: false
      end
    end

    def map_student_form_create_update_respond_to_html
      if successful?
        message = "Candidatura mapeada" # ToDo: improve message
        # as_(:created_model, :model => ERB::Util.h(@record.to_label))
        if params[:dont_close]
          flash.now[:info] = message
          render(action: "map_student_form_create_update")
        else
          flash[:info] = message
          return_to_main
        end
      else
        render(action: "map_student_form_create_update")
      end
    end

    def map_student_form_create_update_respond_to_js
      if successful? && !render_parent?
        #if active_scaffold_config.create.refresh_list
        #  do_refresh_list
        #else
          @record = find_if_allowed(params[:id], :map_student)
          reload_record_on_update
        #end
      end
      render action: "on_map_student_form_create_update"
    end
end
