module StudentApplicationsHelper
  include ApplicationHelper
  include PdfHelper
  def student_application_form_fields_show_column(record, column)
    return "-" if record.form_field_inputs.empty? and record.form_text_inputs.empty? and record.form_file_uploads.empty?

    body = ""
    count = 0

    body += "<table class=\"showtable listed-records-table\">"

    body += "<thead>
              <tr>
                <th>#{I18n.t('activerecord.attributes.form_field.name')}</th>
                <th>#{I18n.t('activerecord.attributes.form_field_input.input')}</th>
              </tr>
            </thead>"

    body += "<tbody class=\"records\">"

    record.form_field_inputs.each do |field|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{field.form_field.name}</td>
                <td>#{field.input}</td>
              </tr>"
    end

    record.form_text_inputs.each do |field|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{field.form_field.name}</td>
                <td>#{field.input}</td>
              </tr>"
    end

    record.form_file_uploads.each do |field|
      count += 1
      tr_class = count.even? ? "even-record" : ""

      body += "<tr class=\"record #{tr_class}\">
                <td>#{field.form_field.name}</td>
                <td>#{link_to field.file.file.extension, form_file_download_url(field.id )}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
    #, field.file.file.basename, field.file.file.extension
  end

  def student_application_letter_requests_show_column(record, column)
    return "-" if record.letter_requests.empty?

    body = ""
    count = 0

    record.letter_requests.each do |letter|
      body += "<h1>#{letter.professor_name rescue "-"} - #{letter.professor_email}</h1>"

      if (letter.is_filled?)
        body += "<table class=\"showtable listed-records-table\">"

        body += "<thead>
                  <tr>
                    <th>#{I18n.t('activerecord.attributes.form_field.name')}</th>
                    <th>#{I18n.t('activerecord.attributes.form_field_input.letter_input')}</th>
                  </tr>
                </thead>"

        body += "<tbody class=\"records\">"

        letter.letter_field_inputs.each do |field|
          count += 1
          tr_class = count.even? ? "even-record" : ""

          body += "<tr class=\"record #{tr_class}\">
                    <td>#{field.form_field.name}</td>
                    <td>#{field.input}</td>
                  </tr>"
        end
        letter.letter_text_inputs.each do |field|
          count += 1
          tr_class = count.even? ? "even-record" : ""

          body += "<tr class=\"record #{tr_class}\">
                <td>#{field.form_field.name}</td>
                <td>#{field.input}</td>
              </tr>"
        end
        letter.letter_file_uploads.each do |field|
          count += 1
          tr_class = count.even? ? "even-record" : ""

          body += "<tr class=\"record #{tr_class}\">
                <td>#{field.form_field.name}</td>
                <td>#{link_to field.file.file.extension, letter_file_download_url(field.id )}</td>
              </tr>"
        end
        body += "</tbody>"
        body += "</table>"
      else
        body += I18n.t('activerecord.attributes.letter_request.not_filled')
      end

    end
    body.html_safe
  end
end