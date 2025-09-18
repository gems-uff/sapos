class ProfessorResearchLinesController < ApplicationController
  authorize_resource

  active_scaffold :professor_research_line do |config|
    columns = [:professor, :research_line]

    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.columns[:professor].form_ui = :record_select
    config.columns[:research_line].form_ui = :record_select

    config.actions.exclude :deleted_records
  end

  record_select
end
