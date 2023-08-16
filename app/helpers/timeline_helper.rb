# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

module TimelineHelper
  class TimelineWidget
    include ActionView::Helpers::JavaScriptHelper

    def initialize
      @events = []
    end

    def add_event(date1, date2, title, attrs = {})
      dates = []
      dates << TimelineWidget.jsdate(date1) unless date1.nil?
      dates << TimelineWidget.jsdate(date2) unless date2.nil?

      @events << "{
        dates: [#{dates.join(',')}],
        title: '#{escape_javascript(title)}',
        attrs: #{attrs.to_json}
      }"
    end

    def add_custom_event(code)
      @events << code
    end

    def events
      "[#{@events.join(',')}]"
    end

    def script(element_id, var_name, days, start_date, end_date)
      "<script>
        var #{var_name} = #{events};
        var timeline = new Chronoline(
          document.getElementById('#{escape_javascript(element_id)}'),
          #{var_name},
          {animated: true,
          draggable: true,
          visibleSpan:  DAY_IN_MILLISECONDS * #{days},
          fitVisibleSpan: false,
          labelFormat: '',
          markToday: false,
          eventHeigh: 3,
          topMargin: 0,
          startDate: #{TimelineWidget.jsdate(start_date)},
          endDate: #{TimelineWidget.jsdate(end_date)},
          floatingSubLabels: false,
          scrollLeft: prevSemester,
          scrollRight: nextSemester
        });
      </script>"
    end


    def self.jsdate(date)
      "new Date(#{date.year}, #{date.month - 1}, #{date.day})"
    end

    def self.color_attrs(color)
      {
        fill: color,
        stroke: color,
      }
    end
  end
end
