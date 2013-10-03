# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ProfessorResearchAreasController < ApplicationController
  authorize_resource

  active_scaffold :professor_research_area do |config|
    columns = [:professor, :research_area]

    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.columns[:professor].form_ui = :record_select
    config.columns[:research_area].form_ui = :record_select

    config.columns[:professor].includes = [:name]
    config.columns[:research_area].includes = [:name]
  end

  record_select
end 