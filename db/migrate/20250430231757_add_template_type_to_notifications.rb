class AddTemplateTypeToNotifications < ActiveRecord::Migration[7.0]
  def up
    add_column :notifications, :template_type, :string, default: "ERB"
    Notification.disable_erb_validation! do 
      ## This must iterate through all assert to make sure paper trail creates ERB verions
      Notification.all.each do |notification|
        notification.template_type = "ERB"
        notification.save!
        notification.paper_trail.save_with_version
      end
    end
    change_column_default :notifications, :template_type, "Liquid" 
  end

  def down
    remove_column :notifications, :template_type
  end
end
