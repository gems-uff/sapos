class ChangeFormTemplatesCodeType < ActiveRecord::Migration[5.1]
  def up
    change_column :form_templates, :code, :text
  end
end
