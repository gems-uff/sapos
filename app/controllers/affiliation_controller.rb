# frozen_string_literal: true

class AffiliationController < ApplicationController
  authorize_resource

  active_scaffold :affiliation do |config|
    columns = [:professor, :institution, :start_date, :end_date]

    config.list.columns = columns
    config.create.columns = columns
    config.update.columns = columns
    config.show.columns = columns

    config.columns[:professor].form_ui = :record_select
    config.columns[:institution].form_ui = :record_select
    config.columns[:start_date].form_ui = :date_picker
    config.columns[:end_date].form_ui = :date_picker
  end
  record_select(
    per_page: 10,
    search_on: [:name],
    order_by: "name",
    full_text_search: true
  )
end
