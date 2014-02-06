class ERBFormatter
  def initialize(hash)
    hash.each do |key, value|
      singleton_class.send(:define_method, key) { value }
    end 
  end

  def localize(date, format)
    time = ((date.class == String) ? Time.parse(date) : date.to_time) 
    I18n.localize(time, :format => format)
  end

  def format(code)
    ERB.new(code, 0).result(binding)
  end
end
