# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ApplicationHelper
  include NumbersHelper

  def optional_navigation(options)
    begin
      render_navigation(options)
    rescue NoMethodError => e
      ""
    end
  end

  def display_none_if_logged_out
    'style="display:none;"'.html_safe unless user_signed_in?
  end

  def signed_in_class
    user_signed_in? ? 'signed-in' : 'signed-out'
  end

  def rescue_blank_text(texts = nil, options = {})
    options[:blank_text] ||= I18n.t('rescue_blank_text')
    options[:method_call] ||= :to_s
    options[:separator] ||= ', '
    texts = [texts] unless texts.kind_of?(Array)
    
    result = texts.keep_if { |text| not text.blank? }
      .collect { |text| text.send(options[:method_call])}

    return options[:blank_text] if result.empty?
    result.join(options[:separator])
  end

  def monthyear2(date, options = {})
    options[:blank_text] ||= I18n.t('rescue_blank_text')
    return options[:blank_text] if date.nil?
    I18n.localize(date, :format => :monthyear2)
  end

  def read_attribute(record, attribute_name)
    return nil if ! record.respond_to?(attribute_name)
    record.send(attribute_name)
  end

  def city_widget(record, options, attributes={})
    return render(:partial => "application/city_widget", :locals => { 
      record: record,
      options: options,
      attributes: attributes,
    })
  end

  def identity_issuing_place_widget(record, options, attributes={})
    return render(:partial => "application/identity_issuing_place_widget", :locals => { 
      record: record,
      options: options,
      attributes: attributes,
    })
  end

end
