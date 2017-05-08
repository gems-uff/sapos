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
        #widths = [50, 160, 350]
        widths = [160, 400]
        student_applications.joins(:student).order('students.name').each do |applied|
          title = [
              ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_name')}: #{applied.student.name}</b>"],
              ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.student_cpf')}: #{applied.student.cpf}</b>"],
              ["<b>#{I18n.t('pdf_content.application_processes.to_pdf.requested_filled_letters')}: #{applied.filled_letters} / #{applied.requested_letters}</b>"]
          ]
          # data = [[]]
          # field_count = applied.form_field_inputs.count + applied.form_text_inputs.count
          data = [
              [{:content => "<b>#{I18n.t('activerecord.attributes.student_application.form_fields')}</b>", :colspan => 2}],
              ["<b>#{I18n.t('activerecord.attributes.form_field.name')}</b>", "<b>#{I18n.t('activerecord.attributes.form_field_input.input')}</b>"]
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
          data += [
              [{:content => "<b>#{I18n.t('activerecord.attributes.student_application.letter_requests')}</b>", :colspan => 2}]
          ]
          #pdf.move_down 5
          pdf.start_new_page
          pdf_table_with_title(pdf, widths, title, '', data, width: 560)
          applied.letter_requests.each do |lrequest|
            ldata = [
                ["<b>#{I18n.t('activerecord.attributes.letter_request.professor_name')}</b>", "<b>#{lrequest.professor_name}</b>"],
                ["<b>#{I18n.t('activerecord.attributes.letter_request.professor_email')}</b>", "<b>#{lrequest.professor_email}</b>"],
                ["<b>#{I18n.t('activerecord.attributes.letter_request.professor_telephone')}</b>", "<b>#{lrequest.professor_telephone}</b>"]
            ]
            if lrequest.is_filled?
              ldata += [
                  [{:content => "<b>#{I18n.t('activerecord.attributes.student_application.form_fields')}</b>", :colspan => 2}],
                  ["<b>#{I18n.t('activerecord.attributes.form_field.name')}</b>", "<b>#{I18n.t('activerecord.attributes.letter_field_input.input')}</b>"]
              ]
              lrequest.letter_field_inputs.each do |linput|
                ldata += [
                    [linput.form_field.name, linput.input]
                ]
              end
              lrequest.letter_text_inputs.each do |ltext|
                ldata += [
                    [ltext.form_field.name, ltext.input]
                ]
              end
            else
              ldata += [
                  [{:content => "<b>#{I18n.t('activerecord.attributes.letter_request.not_filled')}</b>", :colspan => 2}]
              ]
            end
            simple_pdf_table(pdf, widths, '', ldata, width: 560)
            #pdf_table_with_title(pdf, widths, ltitle, '', ldata, width: 560)
          end
        end
      end
    end
  end
end