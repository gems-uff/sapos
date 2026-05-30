class ConvertConsolidateEmailFieldsFromErbToLiquid < ActiveRecord::Migration[7.0]
  
  def convert_erb_to_liquid(original)
    emails_secretaria = original.gsub(/<%=\s*User\.where\(:role_id\s*=>\s*3\)\.map\(&:email\)\.join\(['"];['"]\)\s*%>/, "{% emails Secretaria %}")
    emails_coordenacao = emails_secretaria.gsub(/<%=\s*User\.where\(:role_id\s*=>\s*2\)\.map\(&:email\)\.join\(['"];['"]\)\s*%>/, "{% emails Coordenação %}")
    change_fields = emails_coordenacao.gsub(/<%=\s*var\(:fields\)(\[['"][_a-zA-Z0-9].*?['"]\])\s*%>/, '{{ fields\1 }}')
    change_application = change_fields.gsub(/<%=\s*var\(:application\)\.([_a-zA-Z][_a-zA-Z0-9]*?)\s*%>/, '{{ application.\1 }}')
    change_process = change_application.gsub(/<%=\s*var\(:process\)\.([_a-zA-Z][_a-zA-Z0-9]*?)\s*%>/, '{{ process.\1 }}')
    change_process
  end

  def convert_liquid_to_erb(original)
    emails_secretaria = original.gsub(/\{%\s*emails\s+Secretaria\s*%}/, "<%= User.where(:role_id => 3).map(&:email).join(';') %>")
    emails_coordenacao = emails_secretaria.gsub(/\{%\s*emails\s+Coordenação\s*%}/, "<%= User.where(:role_id => 2).map(&:email).join(';') %>")
    change_fields = emails_coordenacao.gsub(/\{\{\s*fields(\[['"][_a-zA-Z0-9].*?['"]\])\s*\}\}/, '<%= var(:fields)\1 %>')
    change_application = change_fields.gsub(/\{\{\s*application\.([_a-zA-Z][_a-zA-Z0-9]*?)\s*\}\}/, '<%= var(:application).\1 %>')
    change_process = change_application.gsub(/\{\{\s*process\.([_a-zA-Z][_a-zA-Z0-9]*?)\s*\}\}/, '<%= var(:process).\1 %>')
    change_process
  end

  def no_erb_tag(text)
    !(text.include?('<%') || text.include?('%>'))
  end
  
  def no_erb_tags(config)
    no_erb_tag(config["to"]) &&
    no_erb_tag(config["body"]) &&
    no_erb_tag(config["subject"])
  end
    
  def no_liquid_tag(text)
    !(text.include?('{{') ||
    text.include?('}}') ||
    text.include?('{%') ||
    text.include?('%}'))
  end
  
  def no_liquid_tags(config)
    no_liquid_tag(config["to"]) &&
    no_liquid_tag(config["body"]) &&
    no_liquid_tag(config["subject"])
  end
  
  def up
    Admissions::FormField.where(field_type: Admissions::FormField::EMAIL).each do |form_field|
      config = JSON.parse(form_field.configuration)
      next if config["template_type"] != "ERB"
      config["to"] = convert_erb_to_liquid(config["to"])
      config["body"] = convert_erb_to_liquid(config["body"])
      config["subject"] = convert_erb_to_liquid(config["subject"])
      puts "#{form_field.name} (#{form_field.form_template.name})"
      if no_erb_tags(config)
        config["template_type"] = "Liquid"
        form_field.configuration = JSON.dump(config)
        form_field.save!
        puts '..Converted'
      else
        puts '..Incomplete conversion. Kept ERB'
      end
    end
  end

  def down
    Admissions::FormField.disable_erb_validation! do
      Admissions::FormField.where(field_type: Admissions::FormField::EMAIL).each do |form_field|
        config = JSON.parse(form_field.configuration)
        next if config["template_type"] != "Liquid"
        config["to"] = convert_liquid_to_erb(config["to"])
        config["body"] = convert_liquid_to_erb(config["body"])
        config["subject"] = convert_liquid_to_erb(config["subject"])
        puts "#{form_field.name} (#{form_field.form_template.name})"
        if no_liquid_tags(config)
          config["template_type"] = "ERB"
          form_field.configuration = JSON.dump(config)
          form_field.save!
          puts '..Converted'
        else
          puts '..Incomplete conversion. Kept Liquid'
        end
      end
    end
  end

end
