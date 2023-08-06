# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module CourseResearchAreasHelper
  def research_area_form_column(record, options)
    logger.info "  RecordSelect Helper CourseResearchAreasHelper\\research_area_form_column"
    record_select_field :research_area, record.research_area || ResearchArea.new, options
  end

  def course_form_column(record, options)
    logger.info "  RecordSelect Helper CourseResearchAreasHelper\\course_form_column"
    record_select_field :course, record.course || Course.new, options
  end
end
