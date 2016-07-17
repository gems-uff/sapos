module ApplicationProcessesPdfHelper
  def student_applications_table (curr_pdf, options={})
    curr_pdf.group do |pdf|
      application_process ||= options[:application_process]
      student_applications = application_process.student_applications

      unless student_applications.empty?
        title = [
            ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_applications')} #{application_process.name} - #{application_process.year_semester}</b>"],
            ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.start_date')}: #{application_process.start_date}
              #{I18n.t('pdf_content.application_processes.to_pdf.end_date')}: #{application_process.end_date}
              #{I18n.t('pdf_content.application_processes.to_pdf.student_applications_count')}: #{application_process.student_applications_count}</b>"
            ]
        ]
        header = [
              ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_name')}</b>",
               "<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_cpf')}</b>",
               #"<b>#{I18n.t('pdf_content.application_processes.to_pdf.requested_letters')}</b>",
               "<b>#{I18n.t('pdf_content.application_processes.to_pdf.requested_filled_letters')}</b>"]
        ]
        data = student_applications.joins(:student).order('students.name').map do |applied|
          [applied.student.name, applied.student.cpf, "#{applied.requested_letters} / #{applied.filled_letters}"]
        end
        #pdf_list_with_title(pdf, title, data)
        widths = [300, 110, 150]
        pdf_table_with_title(pdf, widths, title, header, data, width: 560)
      end
    end
  end
  def student_applications_complete_table (curr_pdf, options={})
    curr_pdf.group do |pdf|
      application_process ||= options[:application_process]
      student_applications = application_process.student_applications

      unless student_applications.empty?
        title = [
            ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_applications')} #{application_process.name} - #{application_process.year_semester}</b>"],
            ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.start_date')}: #{application_process.start_date}
             #{I18n.t('pdf_content.application_processes.to_pdf.end_date')}: #{application_process.end_date}
             #{I18n.t('pdf_content.application_processes.to_pdf.student_applications_count')}: #{application_process.student_applications_count}</b>"
            ]
        ]
        #simple_pdf_table(pdf, [560], '', title, width: 560)
        pdf_table_with_title(pdf, [560], title, '', [], width: 560)
        widths = [140, 140, 280]
        student_applications.joins(:student).order('students.name').each do |applied|
          data = [
              [{:content => "<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_name')}</b>"}, {:content => applied.student.name, :colspan => 2}],
              ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_cpf')}</b>", {:content => applied.student.cpf, :colspan => 2}],
              ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.requested_filled_letters')}</b>", {:content => "#{applied.requested_letters} / #{applied.filled_letters}", :colspan => 2}]
          ]
          field_count = applied.form_field_inputs.count + applied.form_text_inputs.count
          data += [
              [{:content => "<b>#{I18n.t('activerecord.attributes.student_application.form_fields')}</b>", :rowspan => field_count+1},"<b>#{I18n.t('activerecord.attributes.form_field.name')}</b>", "<b>#{I18n.t('activerecord.attributes.form_field_input.input')}</b>"]
          ]
          applied.form_field_inputs.each do |input|
            data += [
                [input.form_field.name, input.input]
            ]
          end
          applied.form_text_inputs.each do |text|
            data += [
                [text.form_field.name, text.input]
            ]
          end
          # letter_count = applied.letter_requests.count
          # data += [
          #     [{:content => "<b>#{I18n.t('activerecord.attributes.student_application.letter_requests')}</b>", :rowspan => 1+3*letter_count},{:content => "<b>#{}</b>", :colspan => 2}]
          # ]
          # applied.letter_requests.each do |lr|
          #
          # end
          pdf.move_down 1
          simple_pdf_table(pdf, widths, '', data, width: 560)
        end
      end
    end
  end
end