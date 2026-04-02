class ChangeThesisTitleToUnicodeInEnrollments < ActiveRecord::Migration[7.1]
  def change
    return unless ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')

    change_column :enrollments, :thesis_title, :string, collation: Collation.collations[:db_collation]
  end
end
