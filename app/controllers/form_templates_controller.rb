class FormTemplatesController < ApplicationController
  authorize_resource

  def index
    @form_templates = FormTemplate.all
  end

  def new
    @form_template = FormTemplate.new
  end

  def show

  end

  def create
    @form_template = FormTemplate.new(form_template_params)

    if @form_template.save
      redirect_to form_templates_path, notice: 'Form template was successfully created.'
    else
      render :new
    end

  end

  private

  def form_template_params
    params.require(:form_template).permit(:name, :description, :is_letter,
                                          form_fields_attributes: [:id, :field_type, :name, :is_mandatory, :default, :_destroy,
                                                                   form_field_values_attributes: [:id, :is_default, :value, :_destroy]],
                                          application_processes_attributes:[:name, :semester, :year, :start_date, :end_date, :total_letters])
  end
=begin
  active_scaffold :form_template do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :is_letter]
    config.create.label = :create_form_template_label
    #config.columns[:state].form_ui = :select
    #config.columns[:state].clear_link
    config.create.columns = [:name, :description, :is_letter]
    config.nested.add_link(:form_fields)
    #config.update.label = :update_city_label
    #config.update.columns = [:state, :name]
    config.actions.exclude :deleted_records
  end
=end


end