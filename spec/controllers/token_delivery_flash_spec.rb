# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O aviso das telas da seleção sobre para onde o código foi. A recuperação
# do código pelo e-mail (find_by_email) manda uma mensagem por endereço
# gravado, e em MariaDB a busca casa endereços que diferem só por caixa ou
# acento: o candidato que digitou um deles pode ter várias mensagens, e a
# suíte, em SQLite, não monta esse caso pela tela.
RSpec.describe Admissions::ProcessBaseController do
  let(:chave) { "admissions.admissions.find_by_email.success" }
  let(:mensagens) { [{ to: "joão@example.com" }, { to: "joao@example.com" }] }

  def aviso(undelivered)
    described_class.new.send(:token_delivery_flash, chave, "joão@example.com", mensagens,
      undelivered: undelivered, count: 2)
  end

  it "controle: com todas entregues, diz para onde foi" do
    expect(aviso([])).to eq(notice: I18n.t(chave, email: "joão@example.com", count: 2))
  end

  it "com uma das mensagens não entregue, não diz que enviou" do
    expect(aviso([mensagens.first])).to eq(alert: I18n.t("#{chave}_without_email", count: 2))
  end
end
