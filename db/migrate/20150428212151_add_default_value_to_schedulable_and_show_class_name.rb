class AddDefaultValueToSchedulableAndShowClassName < ActiveRecord::Migration
  def self.up
  	change_column_default :course_types, :schedulable, :default => true
  	change_column_default :course_types, :show_class_name, :default => true
  end
  def self.down
  	change_column_default :course_types, :schedulable, :default => nil
  	change_column_default :course_types, :show_class_name, :default => nil
  end

end
