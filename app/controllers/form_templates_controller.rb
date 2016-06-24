class FormTemplatesController < ApplicationController
  authorize_resource

  def index
    FormTemplate.all
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