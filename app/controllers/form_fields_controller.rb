class FormFieldsController < ApplicationController
  authorize_resource
  active_scaffold :form_field do |config|
    config.list.sorting = {:name => 'ASC'}
    config.list.columns = [:name, :field_type, :is_mandatory, :description]
    config.create.label = :create_form_template_label
    #config.columns[:state].form_ui = :select
    #config.columns[:state].clear_link
    config.create.columns = [:name, :description, :field_type]
    #config.nested.add_link(:form_fields)
    #config.update.label = :update_city_label
    #config.update.columns = [:state, :name]
    config.actions.exclude :deleted_records, :update, :delete, :show
  end
end