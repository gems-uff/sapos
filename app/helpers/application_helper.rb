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


  def read_attribute(attribute_name)
    return nil if params[:record].nil? or params[:record][attribute_name].nil?
    params[:record][attribute_name].to_i
  end

  def city_widget(options={})
    options[:country] ||= :address_country
    options[:state] ||= :address_state
    options[:city] ||= :city
    html = ""

    country_id = options[:selected_country] || read_attribute(options[:country]) 
    state_id = options[:selected_state] || read_attribute(options[:state])
    city_id = options[:selected_city] || read_attribute(options[:city])  

    unless state_id.nil?
      state = State.find_by_id(state_id)
      state_id = nil if not state.nil? and state.country_id != country_id
    end
    unless city_id.nil? 
      city = City.find_by_id(city_id)
      city_id = nil if not city.nil? and city.state_id != state_id
    end
    
    html += select_tag(
      "record[#{options[:country]}]", 
      options_for_select([[I18n.translate("helpers.city_widget.select_country"), nil]] + Country.all.collect{|c| [c.name, c.id]}, country_id), 
      {
        class: "city_widget_country", 
        data: {
          :state_dom_id => "#record_#{options[:state]}",
          :city_dom_id => "#record_#{options[:city]}",
          :access_url => states_country_path("*")
        }
      }
    )
    html += select_tag(
      "record[#{options[:state]}]", 
      options_for_select([[I18n.translate("helpers.city_widget.select_state"), nil]] + State.where("country_id" => country_id).collect{|s| [s.name, s.id]}, state_id),
      class: "city_widget_state", 
      data: {
        :city_dom_id => "#record_#{options[:city]}",
        :access_url => cities_state_path("*")
      }
    )

    html += select_tag(
      "record[#{options[:city]}]", 
      options_for_select([[I18n.translate("helpers.city_widget.select_city"), nil]] + City.where("state_id" => state_id).collect{|c| [c.name, c.id]}, city_id)
    )

    html += loading_indicator_tag({ })
  end

  def identity_issuing_place_widget(options={})
    options[:text] ||= ""
    options[:select_field] ||= :identity_issuing_place_select
    options[:text_field] ||= :identity_issuing_place
    options[:show_states_link] ||= :identity_issuing_place_widget_show_states
    options[:show_text_link] ||= :identity_issuing_place_widget_show_text

    country = Configuration.identity_issuing_country
    html = ""
    show_text = true
    unless country.nil?
      states = country.state.collect do |s| 
        show_text = false if s.name == options[:text]
        [s.name, s.name]
      end
      show_text = false if options[:text].empty?

      html += select_tag(
        "record[#{options[:select_field]}]", 
        options_for_select([[I18n.translate("helpers.city_widget.select_state"), ""]] + states, options[:text]),
        class: "identity_issuing_place_widget_select", 
        data: {
          :text_field_id => "#record_#{options[:text_field]}"
        },
        style: "display: #{show_text ? 'none' : 'inline-block'}"
      )
    end
    html += text_field_tag(
      "record[#{options[:text_field]}]", 
      options[:text], 
      class: "text-input",
      maxlength: 255,
      size: 30,
      style: "display: #{show_text ? 'inline-block' : 'none'}"
    )
    unless country.nil?
      html += link_to(
        I18n.translate("helpers.identity_issuing_place_widget.show_states", :country=>country.name),
        "#",
        id: options[:show_states_link],
        class: "identity_issuing_place_widget_show_state",
        data: {
          :hide => "#record_#{options[:text_field]}",
          :show1 => "#record_#{options[:select_field]}",
          :show2 => "##{options[:show_text_link]}",
        },
        style: "display: #{show_text ? 'inline-block' : 'none'}"
      )
      html += link_to(
        I18n.translate("helpers.identity_issuing_place_widget.show_text"),
        "#", 
        id: options[:show_text_link],
        class: "identity_issuing_place_widget_show_text",
        data: {
          :hide => "#record_#{options[:select_field]}",
          :show1 => "#record_#{options[:text_field]}",
          :show2 => "##{options[:show_states_link]}",
        },
        style: "display: #{show_text ? 'none' : 'inline-block'}"
      )
    end
    
    html
  end
end
