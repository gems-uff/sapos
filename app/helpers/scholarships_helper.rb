# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Helper for Scholarships
module ScholarshipsHelper
  include PdfHelper
  include ScholarshipsPdfHelper

  def scholarship_duration_cancel_date_form_column(record, options)
    scholarship_month_year_widget record, options, :cancel_date
  end

  def scholarship_duration_start_date_form_column(record, options)
    scholarship_month_year_widget record, options, :start_date
  end

  def scholarship_duration_end_date_form_column(record, options)
    scholarship_month_year_widget record, options, :end_date
  end

  def scholarship_start_date_form_column(record, options)
    scholarship_month_year_widget record, options, :start_date
  end

  def scholarship_end_date_form_column(record, options)
    scholarship_month_year_widget record, options, :end_date
  end

  def start_date_search_column(record, options)
    scholarship_month_year_widget(
      record, options, :start_date, required: false, multiparameter: false,
                                    date_options: { prefix: options[:name] }
    )
  end

  def end_date_search_column(record, options)
    scholarship_month_year_widget(
      record, options, :end_date, required: false, multiparameter: false,
                                  date_options: { prefix: options[:name] }
    )
  end

  def available_search_column(record, options)
    local_options = {
        include_blank: true
    }

    # day_html_options = {
    #     name: "search[available][day]"
    # }
    month_html_options = {
        name: "search[available][month]"
    }
    year_html_options = {
        name: "search[available][year]"
    }

    html = check_box_tag "search[available][use]", "yes", false, style: "vertical-align: sub;"
    html += label_tag "search[available][use]", I18n.t("activerecord.attributes.scholarship.available_label"), style: "margin: 0 15px;"
    # html = label_tag(:accomplishments_date, I18n.t("activerecord.attributes.enrollment.delayed_phase_date"), style: "margin: 0px 15px")
    # html += select_day(Date.today.day, local_options, day_html_options)
    html += select_month(Date.today.month, local_options, month_html_options)
    html += select_year(Date.today.year, local_options, year_html_options)
    html
  end

  def scholarship_timeline_show_column(record, column)
    block = "<div class='fulltimeline'><div class='timeline' id='scholarship_timeline_#{record.id}'></div>
      <div class='timecaption'>
        <span class='scholarship_desc caption_desc'> #{I18n.t("activerecord.attributes.scholarship.scholarship_caption")} </span>
        <span class='end_date_desc caption_desc'> #{I18n.t("activerecord.attributes.scholarship.end_date_caption")} </span>
        <span class='cancel_date_desc caption_desc'> #{I18n.t("activerecord.attributes.scholarship.cancel_date_caption")} </span>
      </div></div>
    "
    timeline = TimelineHelper::TimelineWidget.new

    record.scholarship_durations.each do |sd|
      extra_text = " | #{I18n.t("activerecord.attributes.scholarship.end_date_tip")}: #{monthyear2(sd.end_date)}}" if sd.was_cancelled?

      timeline.add_event(
        sd.start_date,
        sd.last_date,
        "#{sd.enrollment.to_label}: #{monthyear2(sd.start_date)} - #{monthyear2(sd.last_date)}#{extra_text}",
        TimelineHelper::TimelineWidget.color_attrs(sd.was_cancelled? ? "#AA0000" : "#00AA00")
      )
    end

    timeline.add_event(
      record.start_date,
      record.last_date,
      "#{record.scholarship_number}: #{monthyear2(record.start_date)} - #{monthyear2(record.end_date, blank_text: I18n.t("activerecord.attributes.scholarship.present"))}"
    )

    last_date = record.last_date + 1.month
    start_date = record.start_date - 1.month

    days = [700, (last_date - start_date).to_i].min


    block += timeline.script(
      "scholarship_timeline_#{record.id}",
      "events_#{record.id}",
      days,
      start_date,
      last_date
    )
    block.html_safe
  end

  def scholarship_durations_show_column(record, column)
    return "-" if record.scholarship_durations.empty?

    body = ""
    count = 0

    body += "<table width='100%' class=\"showtable listed-records-table\">"

    body += "<thead>
              <tr>
                <th>#{I18n.t("activerecord.attributes.scholarship_duration.enrollment")}</th>
                <th>#{I18n.t("activerecord.attributes.scholarship_duration.start_date")}</th>
                <th>#{I18n.t("activerecord.attributes.scholarship_duration.end_date")}</th>
                <th>#{I18n.t("activerecord.attributes.scholarship_duration.cancel_date")}</th>
              </tr>
            </thead>"

    body += "<tbody class=\"records\">"

    record.scholarship_durations.each do |sd|
      count += 1
      tr_class = count.even? ? "even-record" : ""
      cancel_date = sd.cancel_date.nil? ? "-" : I18n.localize(sd.cancel_date, format: :monthyear2)
      body += "<tr class=\"record #{tr_class}\">
                <td>#{sd.enrollment.to_label}</td>
                <td>#{I18n.localize(sd.start_date, format: :monthyear2)}</td>
                <td>#{I18n.localize(sd.end_date, format: :monthyear2)}</td>
                <td>#{cancel_date}</td>
              </tr>"
    end

    body += "</tbody>"
    body += "</table>"
    body.html_safe
  end

  def permit_rs_browse_params
    [:page, :update, :utf8]
  end
end
