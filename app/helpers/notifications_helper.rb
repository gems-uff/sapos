# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module NotificationsHelper

  def code_mirror_text_area(column, id, type, options, set_size = false)
    set_size_str = set_size ? ".setSize(null, '#{options[:value].count("\n") + 2}em')" : '';
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
    )#{set_size_str};
    </script>".html_safe
  end

  def code_mirror_view(id, type, value, set_size = false)
    set_size_str = set_size ? ".setSize(null, '#{value.count("\n") + 2}em')" : '';
    "<div id='#{id}'></div>
    <script>
    CodeMirror(document.getElementById('#{id}'),
     {mode: '#{type}',
      value: '#{escape_javascript(value)}',
      indentWithTabs: true,
      smartIndent: true,
      lineNumbers: true,
      matchBrackets : true,
      autofocus: true,
      readOnly: true
     }
    )#{set_size_str};
    </script>".html_safe
  end

  def query_sql_form_column(record, options)
    # code_mirror_text_area(:sql_query_view, "record_query_view_#{record.id}", "text/x-mysql", options.merge(:value => record.sql_query || I18n.t('active_scaffold.notification.sql_query_default')), true, true)
    code_mirror_view("sql_query-view-#{record.id}", "text/x-mysql", (record.query.try(:sql) || ''), true)
  end

  def body_template_form_column(record, options)
    code_mirror_text_area(:body_template, "record_body_template_#{record.id}", "text/html", options.merge(:value => record.body_template || I18n.t('active_scaffold.notification.body_template_default')))
  end

  def next_execution_column(record, options)
    if(record.frequency != I18n.translate("activerecord.attributes.notification.frequencies.manual"))
      I18n.localize(record.next_execution, {:format => :day}) unless record.next_execution.nil? or record.nil?
    else
      "-"
    end
  end

  def sql_query_show_column(record, column)
    code_mirror_view("sql_query-view-#{record.id}", "text/x-mysql", (record.query.try(:sql) || ''))
  end

  def body_template_show_column(record, column)
    code_mirror_view("body_template-view-#{record.id}", "text/html", record.body_template)
  end

  def notification_param_query_param_form_column(record, options)
    options[:value] = record.query_param_id
    label(:record_value_1_params, record.id, ("(#{record.value_type}) ") + record.name) + hidden_field(:record, :query_param, options)
  end

end
