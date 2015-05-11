class AddDefaultValueToSchedulableAndShowClassName < ActiveRecord::Migration
  def self.up
  	change_column_default :course_types, :schedulable, true
  	change_column_default :course_types, :show_class_name, true
  end
  def self.down
  	change_column_default :course_types, :schedulable, nil
  	change_column_default :course_types, :show_class_name, nil
  end

end
