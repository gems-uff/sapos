module NumbersHelper
  class InvalidNumberError < StandardError
    attr_accessor :number

    def initialize(number)
      @number = number
    end
  end

  def number_with_delimiter(number, options = {})
    options.symbolize_keys!

    if options[:format_as]
      return nil if number.nil?
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
    else
      begin
        Float(number)
      rescue ArgumentError, TypeError
        if options[:raise]
          raise InvalidNumberError, number
        else
          return number
        end
      end

      defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
      options = options.reverse_merge(defaults)

      parts = number.to_s.to_str.split('.')
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
      parts.join(options[:separator]).html_safe
    end
  end

  def number_to_grade(number, options = {})
    "#{number/10.0}"
  end

end