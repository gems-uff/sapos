class FixCustomVariableLog < ActiveRecord::Migration
  def up
    Version.where(:item_type => "Configuration").each do |v| 
      v.item_type = "CustomVariable"
      v.save
    end
  end

  def down
  end
end
