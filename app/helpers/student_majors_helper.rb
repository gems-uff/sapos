# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module StudentMajorsHelper
  
  def student_form_column(record, options)
    logger.info "  RecordSelect Helper StudentMajorsHelper\\student_form_column"
    record_select_field :student, record.student || Student.new, options.merge!(class: "text-input")
  end

  def major_form_column(record, options)
    logger.info "  RecordSelect Helper StudentMajorsHelper\\major_form_column"
    record_select_field :major, record.major || Major.new, options.merge!(class: "text-input")
  end

end