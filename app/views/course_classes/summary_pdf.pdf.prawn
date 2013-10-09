prawn_document(:page_layout => :landscape, :filename => 'summary.pdf') do |pdf|
  header(pdf)
  document_title(pdf, "#{I18n.t('pdf_content.course_class.summary.title')}".upcase)

  summary_header(pdf, course_class: @course_class)
  summary_table(pdf, course_class: @course_class)   
  summary_footer(pdf, course_class: @course_class)     
end

