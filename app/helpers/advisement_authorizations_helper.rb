# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module AdvisementAuthorizationsHelper
  
  def professor_form_column(record, options)
  	logger.info "  RecordSelect Helper AdvisementAuthorizationsHelper\\professor_form_column"	
    record_select_field :professor, record.professor || Professor.new, options.merge!(class: "text-input")
  end

end