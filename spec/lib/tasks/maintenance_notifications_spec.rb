# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Caracteriza o caminho do cron que o features/notifications_spec.rb nao
# percorre: a notificacao agrupada (individual: false), a janela que decide quem
# dispara, o reagendamento depois do disparo e o Notifier desligado. E o
# agendamento inteiro -- o que um dia foi do rufus-scheduler (#12) e hoje e do
# StringTimeDelta com o cron (#720).
#
# A consulta e substituida por stub: em MariaDB o Query#run_read_only_query abre
# cliente proprio e nao enxergaria a linha criada dentro da transacao do
# exemplo. O que se mede aqui e o agendamento e a montagem da mensagem, nao o SQL.
RSpec.describe "maintenance:trigger_notifications", type: :task do
  include ActiveSupport::Testing::TimeHelpers

  let(:agora) { Time.zone.local(2026, 3, 10, 12, 0, 0) }

  before(:all) do
    require "rake"
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) do
    Rake::Task["maintenance:trigger_notifications"].reenable
    ActionMailer::Base.deliveries.clear
    allow_any_instance_of(Query).to receive(:execute).and_return(
      { rows: [["Ana", "ana@sapos.test"], ["Beto", "beto@sapos.test"]],
        columns: ["nome", "email"], query: "" }
    )
  end

  def agrupada(**atributos)
    notificacao = FactoryBot.create(
      :notification,
      individual: false, frequency: Notification::DAILY,
      to_template: "secretaria@sapos.test", subject_template: "Resumo do dia",
      body_template: "{% for r in records %}{{ r.nome }};{% endfor %}",
      **atributos
    )
    notificacao.update_column(:next_execution, agora - 2.days)
    notificacao
  end

  def dispara
    travel_to(agora) { Rake::Task["maintenance:trigger_notifications"].invoke }
  end

  it "manda uma mensagem so com todas as linhas da consulta" do
    agrupada

    dispara

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    mensagem = ActionMailer::Base.deliveries.last
    expect(mensagem.subject).to eq("Resumo do dia")
    expect(mensagem.text_part.decoded).to include("Ana;Beto;")
  end

  it "reagenda a notificacao para a proxima ocorrencia depois de disparar" do
    notificacao = agrupada

    dispara

    expect(notificacao.reload.next_execution).to eq(Time.zone.local(2026, 3, 11))
  end

  it "soma o deslocamento da notificacao ao reagendar" do
    notificacao = agrupada(frequency: Notification::MONTHLY, notification_offset: "2d12h")

    dispara

    expect(notificacao.reload.next_execution).to eq(Time.zone.local(2026, 4, 3, 12))
  end

  it "nao dispara nem reagenda a que ainda nao venceu" do
    notificacao = agrupada
    notificacao.update_column(:next_execution, agora + 1.hour)

    dispara

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(notificacao.reload.next_execution).to eq(agora + 1.hour)
  end

  it "ignora a notificacao manual mesmo vencida" do
    notificacao = agrupada(frequency: Notification::MANUAL)
    notificacao.update_column(:next_execution, agora - 2.days)

    dispara

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(notificacao.reload.next_execution).to eq(agora - 2.days)
  end

  # O reagendamento acontece dentro do Notification#execute, antes do envio: com
  # o envio desligado a notificacao perde a ocorrencia em vez de acumular.
  it "com o envio desligado nao entrega, mas reagenda assim mesmo" do
    notificacao = agrupada
    allow(Rails.application.config).to receive(:should_send_emails).and_return(false)

    dispara

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(notificacao.reload.next_execution).to eq(Time.zone.local(2026, 3, 11))
  end
end
