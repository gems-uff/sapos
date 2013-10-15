class AddShowAdvisorNameToDismissalReason < ActiveRecord::Migration
  def change
    add_column :dismissal_reasons, :show_advisor_name, :boolean, default: false
  end
end
