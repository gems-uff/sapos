module AllocationsHelper
  def start_time_form_column(record, options)
    options[:class] += " time_picker"
    text_field :record, :start_time, {
    }.merge(options)
  end
  def end_time_form_column(record, options)
    options[:class] += " time_picker"
    text_field :record, :start_time, {
    }.merge(options)
  end
end