#encoding: UTF-8
RSpec::Matchers.define :have_error do |erro|

  def error_message(record, atributo, erro)
    translation_missing_message = "translation missing:"
    message = I18n.translate("errors.messages.#{erro}")
    if message.include?(translation_missing_message)
      message = I18n.translate("activerecord.errors.models.#{record.class.to_s.underscore}.#{erro}")
      message = message.include?(translation_missing_message) ? I18n.translate("activerecord.errors.models.#{record.class.to_s.underscore}.attributes.#{atributo}.#{erro}") : message
    end
    return message
  end

  chain :on do |atributo|
    @atributo = atributo
  end

  match do |record|
    unless @atributo
      raise "Deve incluir um atributo"
    end
    record.valid?
    mensagem = error_message(record, @atributo, erro.to_s)
    record.errors[@atributo].to_a.detect { |e| e == mensagem }
  end

  failure_message_for_should do |record|
    if @atributo
      %{Esperava que [#{record.errors[@atributo].join(', ')}] incluísse "#{error_message(record, @atributo, erro.to_s)}"}
    end
  end

  failure_message_for_should_not do |record|
    if @atributo
      %{Esperava que [#{record.errors[@atributo].join(', ')}] não incluísse "#{error_message(record, @atributo, erro.to_s)}"}
    end
  end

  description do
    "deve incluir erro de '#{erro.to_s}'"
  end
end