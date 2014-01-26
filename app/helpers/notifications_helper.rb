module NotificationsHelper

  def sql_query_form_column(record, options)
    block = text_field(:record, :sql_query, options)

  end
end