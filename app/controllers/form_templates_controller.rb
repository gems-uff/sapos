class FormTemplatesController < ApplicationController
  authorize_resource

  # def index
  #   @form_templates = FormTemplate.all
  # end
  #
  # def new
  #   @form_template = FormTemplate.new
  # end
  #
  # def show
  #
  # end
  #

  #

  active_scaffold :form_template do |config|
    config.columns.add :get_form_type
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :description, :get_form_type]
    config.create.label = :create_form_template_label
    #config.columns[:state].form_ui = :select
    #config.columns[:state].clear_link
    config.create.columns = [:name, :description, :get_form_type]
    config.nested.add_link(:form_fields)
    config.action_links.add :disable, :type => :member, :crud_type => :update, :method => :put, :position => false, :label => "<i title='#{I18n.t('active_scaffold.delete_link')}' class='fa fa-trash-o'></i>".html_safe
    #config.action_links.add :edit_form, :type => :member, :crud_type => :update, :method => :put, :position => false, :label => "<i title='#{I18n.t('active_scaffold.update')}' class='fa fa-pencil'></i>".html_safe
    #config.update.label = :update_city_label
    #config.update.columns = [:state, :name]
    #config.actions << :duplicate
    #config.duplicate.link.label = "<i title='#{I18n.t('active_scaffold.duplicate')}' class='fa fa-copy'></i>".html_safe
    config.actions.exclude :deleted_records, :update, :delete, :show
  end

  def beginning_of_chain
    super.enabled
  end

  def create
    @form_template = FormTemplate.new(form_template_params)

    if @form_template.save
      redirect_to form_templates_path, notice: 'Form template was successfully created.'
    else
      render :new
    end

  end

  def disable
    process_action_link_action do |record|
      if record.update(:status => 'DELETED')
        flash[:info] = "Formulário #{record.name} - #{record.get_form_type} removido com sucesso"
      else
        flash[:error] = "Não foi possível remover #{record.name} - #{record.get_form_type}"
      end
    end
  end


  private

  def form_template_params
    params.require(:form_template).permit(:name, :description, :is_letter, :status,
                                          form_fields_attributes: [:id, :field_type, :name, :is_mandatory, :default, :_destroy,
                                                                   form_field_values_attributes: [:id, :is_default, :value, :_destroy]],
                                          application_processes_attributes:[:name, :semester, :year, :start_date, :end_date, :total_letters])
  end

end