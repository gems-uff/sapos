# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Main helpers of the application
module ApplicationHelper
  include NumbersHelper

  def optional_navigation(options)
    render_navigation(options)
  rescue NoMethodError
    ""
  end

  def display_none_if_logged_out
    'style="display:none;"'.html_safe unless user_signed_in?
  end

  def signed_in_class
    user_signed_in? ? "signed-in" : "signed-out"
  end

  def rescue_blank_text(texts = nil, options = {})
    options[:blank_text] ||= I18n.t("rescue_blank_text")
    options[:method_call] ||= :to_s
    options[:separator] ||= ", "
    texts = [texts] unless texts.kind_of?(Array)

    result = texts.keep_if { |text| not text.blank? }
      .collect { |text| text.send(options[:method_call]) }

    return options[:blank_text] if result.empty?
    result.join(options[:separator])
  end

  def monthyear2(date, options = {})
    options[:blank_text] ||= I18n.t("rescue_blank_text")
    return options[:blank_text] if date.nil?
    I18n.localize(date, format: :monthyear2)
  end

  def read_attribute(record, attribute_name)
    return nil unless record.respond_to?(attribute_name)

    record.send(attribute_name)
  end

  def city_widget(record, options, attributes = {})
    render(partial: "application/city_widget", locals: {
      record: record,
      options: options,
      attributes: attributes
    })
  end

  def identity_issuing_place_widget(record, options, attributes = {})
    render(partial: "application/identity_issuing_place_widget", locals: {
      record: record,
      options: options,
      attributes: attributes,
    })
  end

  def month_year_widget(record, options, attribute, extra = {})
    config = ActiveScaffold::Config::Core.new(record.class)
    extra[:date_options] ||= {}
    extra[:select_options] ||= {}
    extra[:required] ||= extra[:required].nil? ?
      config.columns[attribute].required? :
      extra[:required]
    extra[:multiparameter] ||= extra[:multiparameter].nil? ?
      true :
      extra[:multiparameter]
    extra[:force_send] ||= extra[:force_send].nil? ? false : extra[:force_send]
    year_range = CustomVariable.month_year_range
    start_year = Time.now.year - year_range[0]
    end_year = Time.now.year + year_range[1]
    start_year, end_year = end_year, start_year if year_range[2]
    date_options = {
      discard_day: true,
      start_year: start_year,
      end_year: end_year
    }.merge(extra[:date_options])
    unless extra[:required]
      date_options[:include_blank] = true
      date_options[:default] = nil
    end
    render(partial: "application/month_year_widget",
           locals: { record: record,
                     options: options,
                     date_options: options.merge(date_options),
                     attribute: attribute,
                     extra: extra })
  end

  def code_mirror_text_area_widget(column, id, type, options, set_size = false)
    set_size_str = set_size ?
      ".setSize(null, '#{options[:value].count("\n") + 2}em')" :
      ""
    block = text_area(:record, :sql_query, options)
    block + "<script>
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

  def code_mirror_view_widget(id, type, value, set_size = false)
    set_size_str = set_size ?
      ".setSize(null, '#{value.count("\n") + 2}em')" :
      ""
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
end
