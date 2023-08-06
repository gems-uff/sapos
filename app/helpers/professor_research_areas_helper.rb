# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module ProfessorResearchAreasHelper
  def research_area_form_column(record, options)
    logger.info "  RecordSelect Helper ProfessorResearchAreasHelper\\research_area_form_column"
    record_select_field :research_area, record.research_area || ResearchArea.new, options
  end

  def professor_form_column(record, options)
    logger.info "  RecordSelect Helper ProfessorResearchAreasHelper\\professor_form_column"
    record_select_field :professor, record.professor || Professor.new, options
  end
end
