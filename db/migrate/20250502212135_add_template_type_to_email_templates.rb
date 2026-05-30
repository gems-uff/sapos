class AddTemplateTypeToEmailTemplates < ActiveRecord::Migration[7.0]
  def up
    add_column :email_templates, :template_type, :string, default: "ERB"
    EmailTemplate.disable_erb_validation! do 
      ## This must iterate through all assert to make sure paper trail creates ERB verions
      EmailTemplate.all.each do |email_template|
        email_template.template_type = "ERB"
        email_template.save!
        email_template.paper_trail.save_with_version
      end
    end
    change_column_default :email_templates, :template_type, "Liquid" 
  end

  def down
    remove_column :email_templates, :template_type
  end
end
