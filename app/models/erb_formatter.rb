class ERBFormatter
  def initialize(hash)
    hash.each do |key, value|
      singleton_class.send(:define_method, key) { value }
    end 
  end

  def localize(date, format)
    I18n.localize(Time.parse(date), :format => format)
  end

  def format(code)
    ERB.new(code, 0).result(binding)
  end
end
