module NotificationsHelper

  def sql_query_form_column(record, options)
    block = text_area(:record, :sql_query, options.merge(:value => record.sql_query || "SELECT * FROM..."))
    block += "<script>
    CodeMirror.fromTextArea(document.getElementById('record_sql_query_#{record.id}'),
     {mode: 'text/x-mysql',
      indentWithTabs: true,
      smartIndent: true,
      lineNumbers: true,
      matchBrackets : true,
      autofocus: true
     }
    );
    </script>".html_safe
  end
end