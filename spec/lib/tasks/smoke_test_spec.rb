# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"
require "rake"

# O smoke test de e-mail roda no deploy e no job smoke-test do CI, em
# RAILS_ENV=production -- e em nenhum outro lugar. Foi assim que a quebra de
# `ActionMailer::Base.mail(...)` no Rails 8.1 so apareceu depois do salto, e a
# task a engole num `puts` + `exit 1`, que ninguem le a nao ser quem faz o deploy
# a mao. Este exemplo traz o caminho para dentro da suite: a task tem de entregar
# UMA mensagem pelo delivery_method de teste, com os campos do smoke test. Com o
# codigo antigo ela sai por `exit 1`, e o SystemExit derruba o exemplo.
RSpec.describe "smoke_test:check_mailer" do
  before(:each) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["smoke_test:check_mailer"].reenable
    ActionMailer::Base.deliveries.clear
  end

  # A task sai por `exit 1` em qualquer falha, e SystemExit atravessa o RSpec e
  # mata o processo inteiro sem sumario -- vermelho, mas mudo. Aqui ele vira
  # falha do exemplo, com o motivo que a task imprimiu.
  def executar_task
    saida = StringIO.new
    $stdout = saida
    Rake::Task["smoke_test:check_mailer"].invoke
    saida.string
  rescue SystemExit => e
    raise "a task saiu com `exit #{e.status}` em vez de entregar:\n#{saida.string}"
  ensure
    $stdout = STDOUT
  end

  it "entrega a mensagem de validacao pelo mailer concreto" do
    saida = nil
    expect { saida = executar_task }.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(saida).to include("Sucesso")

    mensagem = ActionMailer::Base.deliveries.last
    expect(mensagem.to).to eq(["teste-sistema@sapos.ic.uff.br"])
    expect(mensagem.from).to eq(["teste-sistema@sapos.ic.uff.br"])
    expect(mensagem.subject).to eq("[SAPOS] Validação de Deploy")
  end
end
