class RemoveIsEnabledFromFormTemplate < ActiveRecord::Migration
  def change
    remove_column :form_templates, :is_enabled
  end
end
