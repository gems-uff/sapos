class ChangeCustomVariableValueLength < ActiveRecord::Migration[6.0]
  def up
    change_column :custom_variables, :value, :text
  end

  def down
    add_column :custom_variables, :temp_value, :string
  
    CustomVariable.find_each do |variable|
      temp_value = variable.value
      if temp_value.length > 255
        temp_value = temp_value[0, 254]
      end

      variable.update_column(:temp_value, temp_value)
    end

    remove_column :custom_variables, :value
    rename_column :custom_variables, :temp_value, :value
  end
end
