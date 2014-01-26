module NotificationsHelper

  def code_mirror_text_area(column, id, type, options)
    block = text_area(:record, :sql_query, options)
    block += "<script>
    CodeMirror.fromTextArea(document.getElementById('#{id}'),
     {mode: '#{type}',
      indentWithTabs: true,
      smartIndent: true,
      lineNumbers: true,
      matchBrackets : true,
      autofocus: true
     }
    );
    </script>".html_safe
  end

  def sql_query_form_column(record, options)
    code_mirror_text_area(:sql_query, "record_sql_query_#{record.id}", "text/x-mysql", options.merge(:value => record.sql_query || I18n.t('active_scaffold.notification.sql_query_default')))
  end

  def body_template_form_column(record, options)
    code_mirror_text_area(:body_template, "record_body_template_#{record.id}", "text/html", options.merge(:value => record.body_template || I18n.t('active_scaffold.notification.body_template_default')))
  end
end