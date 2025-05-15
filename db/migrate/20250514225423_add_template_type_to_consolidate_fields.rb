class AddTemplateTypeToConsolidateFields < ActiveRecord::Migration[7.0]
  def up
    Admissions::FormField.disable_erb_validation! do
      ## This must iterate through all consolidation fields to make sure paper trail creates ERB verions
      Admissions::FormField.where(field_type: Admissions::FormField::CODE).each do |form_field|
        config = JSON.parse(form_field.configuration)
        config["template_type"] = "Ruby"
        form_field.configuration = JSON.dump(config)
        form_field.save!
        form_field.paper_trail.save_with_version
      end
      Admissions::FormField.where(field_type: Admissions::FormField::EMAIL).each do |form_field|
        config = JSON.parse(form_field.configuration)
        config["template_type"] = "ERB"
        form_field.configuration = JSON.dump(config)
        form_field.save!
        form_field.paper_trail.save_with_version
      end
    end
  end

  def down
    Admissions::FormField.disable_erb_validation! do 
      Admissions::FormField.where(field_type: [Admissions::FormField::CODE, Admissions::FormField::EMAIL]).each do |form_field|
        config = JSON.parse(form_field.configuration)
        config.delete("template_type")
        form_field.configuration = JSON.dump(config)
        form_field.save!
      end
    end
  end
end
