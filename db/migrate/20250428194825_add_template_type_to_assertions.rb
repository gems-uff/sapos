class AddTemplateTypeToAssertions < ActiveRecord::Migration[7.0]

  def up
    add_column :assertions, :template_type, :string, default: "ERB"
    Assertion.disable_erb_validation! do 
      ## This must iterate through all assert to make sure paper trail creates ERB verions
      Assertion.all.each do |assertion|
        assertion.template_type = "ERB"
        assertion.save!
        assertion.paper_trail.save_with_version
      end
    end
    change_column_default :assertions, :template_type, "Liquid" 
  end

  def down
    remove_column :assertions, :template_type
  end
end
