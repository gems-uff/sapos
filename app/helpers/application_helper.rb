# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Main helpers of the application
module ApplicationHelper
  include NumbersHelper

  @@config = YAML.load_file("#{Rails.root}/config/properties.yml")
  @@range = @@config["scholarship_year_range"]

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

  def scholarship_month_year_widget(record, options, attribute, extra = {})
    config = ActiveScaffold::Config::Core.new(record.class)
    extra[:date_options] ||= {}
    extra[:select_options] ||= {}
    extra[:required] ||= extra[:required].blank? ? config.columns[attribute].required? : extra[:required]
    extra[:multiparameter] ||= extra[:multiparameter].blank? ? true : extra[:multiparameter]
    extra[:force_send] ||= extra[:force_send].blank? ? false : extra[:force_send]
    date_options = { discard_day: true,
                     start_year: Time.now.year - @@range,
                     end_year: Time.now.year + @@range }.merge(extra[:date_options])
    unless extra[:required]
      date_options[:include_blank] = true
      date_options[:default] = nil
    end
    render(partial: "application/scholarship_month_year_widget",
           locals: { record: record,
                     options: options,
                     date_options: options.merge(date_options),
                     attribute: attribute,
                     extra: extra })
  end
end
