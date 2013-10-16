# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ProfessorResearchAreasHelper

  def research_area_form_column(record, options)
    record_select_field :research_area, record.research_area || ResearchArea.new, options
  end

  def professor_form_column(record, options)
    record_select_field :professor, record.professor || Professor.new, options
  end
  
end