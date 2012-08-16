module DismissalsHelper
  @@config = YAML::load_file("#{Rails.root}/config/properties.yml")
  @@range = @@config["scholarship_year_range"]

  def date_form_column(record,options)
    date_select :record, :date, {
        :discard_day => true,
        :start_year => Time.now.year - @@range,
        :end_year => Time.now.year + @@range,
        :include_blank => true,
        :default => nil,
    }.merge(options)
  end
end