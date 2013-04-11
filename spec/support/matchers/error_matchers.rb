#encoding: UTF-8
RSpec::Matchers.define :have_error do |erro|

  def error_message(record, atributo, erro)
    I18n.translate("errors.messages.#{erro}")
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