module NumbersHelper
  class InvalidNumberError < StandardError
    attr_accessor :number
    def initialize(number)
      @number = number
    end
  end

  def number_with_delimiter(number, options = {})
    return nil if number.nil?

    options.symbolize_keys!

    defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    formated_number = I18n.translate(:"number.#{options[:format_as]}.format", :locale => options[:locale], :default => {})
    defaults = defaults.merge(formated_number)

    options = options.reverse_merge(defaults)

    begin
      send("number_to_#{options[:format_as]}", number, options || {}).html_safe
    rescue InvalidNumberError => e
      if options[:raise]
        raise
      else
        e.number.to_s.html_safe? ? "#{e.number}".html_safe : "#{e.number}"
      end
    end

  end

  def number_to_grade(number, options = {})
    "#{number/10.0}"
  end

end