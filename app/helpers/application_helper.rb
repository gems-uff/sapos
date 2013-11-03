# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ApplicationHelper
  include NumbersHelper

  def display_none_if_logged_out
    'style="display:none;"'.html_safe unless user_signed_in?
  end

  def transparent_if_logged_out
    'style="background: transparent;border: 0;"'.html_safe unless user_signed_in?
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
end
