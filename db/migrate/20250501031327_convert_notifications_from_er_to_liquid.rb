class ConvertNotificationsFromErToLiquid < ActiveRecord::Migration[7.0]
  
  def convert_erb_to_liquid(original)
    emails_secretaria = original.gsub(/<%=\s*User\.where\(:role_id\s*=>\s*3\)\.map\(&:email\)\.join\(['"];['"]\)\s*%>/, "{% emails Secretaria %}")
    emails_coordenacao = emails_secretaria.gsub(/<%=\s*User\.where\(:role_id\s*=>\s*2\)\.map\(&:email\)\.join\(['"];['"]\)\s*%>/, "{% emails Coordenação %}")
    change_open_for = emails_coordenacao.gsub(/<%\s*records\.each\s+do\s*\|record\|\s*%>/, '{% for record in records %}')
    change_close_for = change_open_for.gsub(/<%\s*end\s*%>/, '{% endfor %}')
    change_localize_attribute = change_close_for.gsub(/<%=\s*localize\(record\[['"]([_a-zA-Z][_a-zA-Z0-9]*?)['"]\]\s*,\s*:\s*([_a-zA-Z][_a-zA-Z0-9]*?)\s*\)\s*%>/, "{{ record.\\1 | localize: '\\2' }}")
    change_record_attributes = change_localize_attribute.gsub(/<%=\s*record\[['"]([_a-zA-Z][_a-zA-Z0-9]*?)['"]\]\s*%>/, '{{ record.\1 }}')
    change_localize_vars = change_record_attributes.gsub(/<%=\s*localize\(var\(['"]([_a-zA-Z][_a-zA-Z0-9]*?)['"]\)\s*,\s*:\s*([_a-zA-Z][_a-zA-Z0-9]*?)\s*\)\s*%>/, "{{ \\1 | localize: '\\2' }}")
    change_vars = change_localize_vars.gsub(/<%=\s*var\(['"]([_a-zA-Z][_a-zA-Z0-9]*?)['"]\)\s*%>/, '{{ \1 }}')
    change_vars
  end
  
  def convert_liquid_to_erb(original)
    emails_secretaria = original.gsub(/\{%\s*emails\s+Secretaria\s*%}/, "<%= User.where(:role_id => 3).map(&:email).join(';') %>")
    emails_coordenacao = emails_secretaria.gsub(/\{%\s*emails\s+Coordenação\s*%}/, "<%= User.where(:role_id => 2).map(&:email).join(';') %>")
    change_open_for = emails_coordenacao.gsub(/\{%\s*for\s+record\s+in\s+records\s*%}/, '<% records.each do |record| %>')
    change_close_for = change_open_for.gsub(/\{%\s*endfor\s*%\}/, '<% end %>')
    change_localize_attribute = change_close_for.gsub(/\{\{\s*record\.([_a-zA-Z][_a-zA-Z0-9]*?)\s*\|\s*localize:\s*['"]([_a-zA-Z][_a-zA-Z0-9]*?)['"]\s*\}\}/, "<%= localize(record['\\1'], :\\2) %>")
    change_record_attributes = change_localize_attribute.gsub(/\{\{\s*record\.([_a-zA-Z][_a-zA-Z0-9]*?)\s*\}\}/, "<%= record['\\1'] %>")
    change_localize_vars = change_record_attributes.gsub(/\{\{\s*([_a-zA-Z][_a-zA-Z0-9]*?)\s*\|\s*localize:\s*['"]([_a-zA-Z][_a-zA-Z0-9]*?)['"]\s*\}\}/, "<%= localize(var('\\1'), :\\2) %>")
    change_vars = change_localize_vars.gsub(/\{\{\s*([_a-zA-Z][_a-zA-Z0-9]*?)\s*\}\}/, "<%= var('\\1') %>")
    change_vars
  end

  def no_erb_tag(text)
    !(text.include?('<%') || text.include?('%>'))
  end
  
  def no_erb_tags(notification)
    no_erb_tag(notification.to_template) &&
    no_erb_tag(notification.body_template) &&
    no_erb_tag(notification.subject_template)
  end
    
  def no_liquid_tag(text)
    !(text.include?('{{') ||
    text.include?('}}') ||
    text.include?('{%') ||
    text.include?('%}'))
  end
  
  def no_liquid_tags(notification)
    no_liquid_tag(notification.to_template) &&
    no_liquid_tag(notification.body_template) &&
    no_liquid_tag(notification.subject_template)
  end
  
  def up
    Notification.where(template_type: "ERB").each do |notification|
      notification.to_template = convert_erb_to_liquid(notification.to_template)
      notification.body_template = convert_erb_to_liquid(notification.body_template)
      notification.subject_template = convert_erb_to_liquid(notification.subject_template)
      puts notification.title
      if no_erb_tags(notification)
        notification.template_type = "Liquid"
        notification.save!
        puts '..Converted'
      else
        puts '..Incomplete conversion. Kept ERB'
      end
    end
  end

  def down
    Notification.disable_erb_validation! do 
      Notification.where(template_type: "Liquid").each do |notification|
        notification.to_template = convert_liquid_to_erb(notification.to_template)
        notification.body_template = convert_liquid_to_erb(notification.body_template)
        notification.subject_template = convert_liquid_to_erb(notification.subject_template)
        puts notification.title
        if no_liquid_tags(notification)
          notification.template_type = "ERB"
          notification.save!
          puts '..Converted'
        else
          puts '..Incomplete conversion. Kept Liquid'
        end
      end
    end
  end  
end
