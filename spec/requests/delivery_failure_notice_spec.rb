# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A falha de entrega de um e-mail não derruba a tela (Notifier.report_failure):
# vai para o log do servidor e para o e-mail de erro -- que, com o servidor de
# e-mail parado, também não sai. A tela é o único lugar em que quem está nela
# fica sabendo, e não pode dizer que enviou o que não saiu.
#
# A falha se monta no Mail::TestMailer, sem stub do Notifier.
RSpec.describe "Tela que anuncia envio de e-mail, com a entrega falhando", type: :request do
  def falha_na_entrega!
    allow_any_instance_of(Mail::TestMailer).to receive(:deliver!).and_raise(Errno::ECONNREFUSED)
    allow(ExceptionNotifier).to receive(:notify_exception)
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  describe "código da inscrição na seleção" do
    before(:each) do
      template = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
      @processo = FactoryBot.create(
        :admission_process, name: "Processo", simple_url: "envio-falho",
        form_template: template, require_session: true,
        start_date: Date.current - 10.days, end_date: Date.current + 10.days,
        edit_date: Date.current + 20.days
      )
    end

    def pede_inscricao
      post admission_path(@processo.simple_url), params: {
        admissions_admission_application: { name: "Pessoa", email: "pessoa@example.com" }
      }
    end

    it "controle: com a entrega, diz para onde o código foi" do
      pede_inscricao

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).to eq(["pessoa@example.com"])
      expect(flash[:notice]).to eq(
        I18n.t("admissions.admissions.create.token_sent", email: "pessoa@example.com")
      )
    end

    it "sem a entrega, não diz que enviou e manda procurar a secretaria" do
      falha_na_entrega!

      pede_inscricao

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(flash[:notice]).to be_nil
      expect(flash[:alert]).to eq(I18n.t("admissions.admissions.create.token_sent_without_email"))
    end

    # O modelo do e-mail é editável pela tela; um destinatário que renderiza
    # vazio (variável com erro de digitação) não entrega nada.
    def modelo_do_codigo(to)
      FactoryBot.create(
        :email_template, name: "admissions/admissions:send_token", template_type: "Liquid",
        enabled: true, to: to, subject: "Código", body: "Seu código: {{ record.token }}"
      )
    end

    it "controle: com o modelo editado e o destinatário certo, diz para onde foi" do
      modelo_do_codigo("{{ record.email }}")

      pede_inscricao

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).to eq(["pessoa@example.com"])
      expect(flash[:notice]).to eq(
        I18n.t("admissions.admissions.create.token_sent", email: "pessoa@example.com")
      )
    end

    it "com o destinatário do modelo vazio, não diz que enviou" do
      modelo_do_codigo("{{ record.emial }}")

      pede_inscricao

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(flash[:notice]).to be_nil
      expect(flash[:alert]).to eq(I18n.t("admissions.admissions.create.token_sent_without_email"))
    end
  end

  describe "Enviar agora, na notificação" do
    before(:each) do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "envio.falho@ic.uff.br")
      query = FactoryBot.create(:query, name: "alunos", sql: "select 'linha' as coluna")
      @notification = FactoryBot.create(
        :notification, query: query, title: "Prazos",
        to_template: "destino@example.com", subject_template: "Prazo",
        body_template: "Prezado aluno"
      )
      ActionMailer::Base.deliveries.clear
    end

    let(:sucesso) { I18n.t("active_scaffold.notification.execute_now_success") }

    it "controle: com a entrega, diz que disparou" do
      post execute_now_notification_path(@notification), xhr: true

      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(response.body).to include(sucesso)
    end

    it "sem a entrega, diz quantas mensagens não saíram" do
      falha_na_entrega!

      post execute_now_notification_path(@notification), xhr: true

      expect(ActionMailer::Base.deliveries).to be_empty
      expect(response.body).not_to include(sucesso)
      expect(response.body).to include(
        I18n.t("active_scaffold.notification.execute_now_failure", count: 1, total: 1)
      )
    end

    it "com destinatário vazio numa linha, diz que ela não saiu" do
      @notification.query.update!(sql: "select 'a@example.com' as email union all select '' as email")
      @notification.update!(to_template: "{{ email }}")

      post execute_now_notification_path(@notification), xhr: true

      expect(ActionMailer::Base.deliveries.flat_map(&:to)).to eq(["a@example.com"])
      expect(response.body).not_to include(sucesso)
      expect(response.body).to include(
        I18n.t("active_scaffold.notification.execute_now_failure", count: 1, total: 2)
      )
    end
  end
end
