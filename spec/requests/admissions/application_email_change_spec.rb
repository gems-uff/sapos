# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A troca de e-mail pedida pelo candidato só vale depois de confirmada pelo
# endereço novo (issue #752). Antes a troca valia ao gravar o formulário: o
# código era renovado e mandado ao endereço novo, e quem digitava o endereço
# errado perdia a inscrição. Agora o pedido fica pendente, um link de validação
# segue para o endereço novo, e até a confirmação valem o e-mail e o código de
# antes. Confirmada a troca, o código é renovado e segue para o endereço novo,
# como em toda troca de e-mail (application_code_ownership_spec.rb).
RSpec.describe "Troca de e-mail da inscricao pelo candidato", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  def formato_do_codigo
    /[2346789BCDFGHJKMPQRTVWXY]{6}-[2346789BCDFGHJKMPQRTVWXY]{6}-[2346789BCDFGHJKMPQRTVWXY]{6}/
  end

  before(:each) do
    @enviados = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviados.concat(notifications) }
    allow(ExceptionNotifier).to receive(:notify_exception)

    @template = create_admission_template(
      "Com e-mail", { "Dado" => Admissions::FormField::STRING, "Correio" => Admissions::FormField::STRING }
    )
    @correio = @template.fields.find_by!(name: "Correio")
    @correio.update!(sync: Admissions::FormField::SYNC_EMAIL)
    datas = {
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    }
    @processo = FactoryBot.create(
      :admission_process, name: "Sem sessao", simple_url: "troca-sem-sessao",
      form_template: @template, require_session: false, **datas
    )
    @com_sessao = FactoryBot.create(
      :admission_process, name: "Com sessao", simple_url: "troca-com-sessao",
      form_template: @template, require_session: true, **datas
    )
  end

  def navegador
    open_session.tap { |sessao| sessao.host! "www.example.com" }
  end

  def campos(inscricao, valores)
    @template.fields.order(:id).each_with_index.to_h do |campo, i|
      entrada = { form_field_id: campo.id, value: valores[campo.name] }
      existente = inscricao&.filled_form&.fields&.find_by(form_field_id: campo.id)
      entrada[:id] = existente.id if existente
      [i.to_s, entrada]
    end
  end

  # Inscrição enviada pelo formulário, em processo sem sessão; devolve o código
  # que a mensagem levou.
  def inscrita(email, dado: "dado")
    navegador.post admission_apply_index_path(admission_id: @processo.simple_id), params: { record: {
      name: "Pessoa", filled_form_attributes: {
        enable_submission: "1", fields_attributes: campos(nil, { "Dado" => dado, "Correio" => email }),
      },
    } }
    codigo_recebido(email)
  end

  # Envio do formulário de uma inscrição que já existe.
  def enviar(sessao, processo, codigo, valores)
    inscricao = Admissions::AdmissionApplication.find_by!(token: codigo)
    sessao.put admission_apply_path(admission_id: processo.simple_id, id: codigo), params: { record: {
      filled_form_attributes: {
        id: inscricao.filled_form.id, enable_submission: "1", fields_attributes: campos(inscricao, valores),
      },
    } }
  end

  def para(email)
    @enviados.select { |mensagem| mensagem[:to] == email }
  end

  def codigo_recebido(email)
    para(email).last&.dig(:body)&.slice(formato_do_codigo)
  end

  # O caminho do link de validação que a última mensagem para o endereço traz.
  def link_recebido(email)
    endereco = para(email).reverse.filter_map { |m| m[:body][%r{https?://\S+/admissions/email_change/[\w-]+}] }.first
    URI(endereco).path if endereco
  end

  def abre?(sessao, processo, codigo)
    sessao.get admission_apply_path(admission_id: processo.simple_id, id: codigo)
    sessao.response.successful?
  end

  def entrar(sessao, processo, email, codigo)
    sessao.post find_admissions_path, params: {
      admissions_admission_application: { email: email, token: codigo, _source: processo.simple_id },
    }
  end

  def valor_do_campo(inscricao, campo)
    inscricao.filled_form.fields.find_by(form_field_id: campo.id)&.value
  end

  def pagina_seguinte(sessao)
    sessao.follow_redirect! if sessao.response.redirect?
    sessao.response.body
  end

  describe "o pedido" do
    before(:each) do
      @antigo = inscrita("pessoa@example.com")
      @inscricao = Admissions::AdmissionApplication.find_by!(token: @antigo)
      @enviados.clear
      @sessao = navegador
    end

    def pedir_troca(email = "nova@example.com", dado: "dado novo")
      enviar(@sessao, @processo, @antigo, { "Dado" => dado, "Correio" => email })
    end

    it "mantem o e-mail e o codigo, e guarda o endereco novo como pendente" do
      pedir_troca

      @inscricao.reload
      expect(@inscricao.email).to eq("pessoa@example.com")
      expect(@inscricao.token).to eq(@antigo)
      expect(@inscricao.pending_email).to eq("nova@example.com")
      expect(@inscricao.email_change_pending?).to be(true)
      expect(@sessao.response.location).to end_with(
        admission_apply_path(admission_id: @processo.simple_id, id: @antigo)
      )
      expect(abre?(@sessao, @processo, @antigo)).to be(true)
    end

    it "grava o resto do formulario, e o campo sincronizado segue com o endereco em vigor" do
      pedir_troca

      @inscricao.reload
      expect(@inscricao.filled_form.fields.joins(:form_field).find_by(form_field: { name: "Dado" }).value)
        .to eq("dado novo")
      expect(valor_do_campo(@inscricao, @correio)).to eq("pessoa@example.com")
    end

    it "manda o link de validacao para o endereco novo, sem o codigo da inscricao" do
      pedir_troca

      expect(link_recebido("nova@example.com")).to be_present
      expect(para("nova@example.com").size).to eq(1)
      expect(para("nova@example.com").first[:body]).not_to match(formato_do_codigo)
      expect(para("nova@example.com").first[:body]).to include(@inscricao.identifier)
      expect(link_recebido("pessoa@example.com")).to be_nil
    end

    it "nao guarda no banco o codigo do link" do
      pedir_troca

      codigo_do_link = link_recebido("nova@example.com").split("/").last
      gravado = @inscricao.reload.attributes.values.map(&:to_s)
      expect(gravado).not_to include(codigo_do_link)
      expect(@inscricao.email_change_digest).to be_present
    end

    it "avisa, ao gravar e na tela da inscricao, que a troca aguarda confirmacao" do
      pedir_troca

      aviso_do_envio = I18n.t("admissions.apply.update.email_change_requested", email: "nova@example.com")
      expect(pagina_seguinte(@sessao)).to include(ERB::Util.html_escape(aviso_do_envio))

      @sessao.get admission_apply_path(admission_id: @processo.simple_id, id: @antigo)
      expect(@sessao.response.body).to include(
        ERB::Util.html_escape(I18n.t("admissions.apply.show.email_change_pending", email: "nova@example.com"))
      )
    end

    it "nao entrega o codigo ao endereco novo pela recuperacao, e segue entregando ao antigo" do
      pedir_troca
      @enviados.clear

      entrar(navegador, @processo, "nova@example.com", "forgot")
      expect(@enviados).to be_empty

      entrar(navegador, @processo, "pessoa@example.com", "forgot")
      expect(codigo_recebido("pessoa@example.com")).to eq(@antigo)
    end

    it "recusa o endereco novo que outra inscricao do processo usa, sem deixar pedido pendente" do
      create_application(@processo, name: "Ocupante", email: "ocupado@example.com")

      pedir_troca("ocupado@example.com")

      expect(@sessao.response).to have_http_status(:ok)
      expect(@inscricao.reload.email).to eq("pessoa@example.com")
      expect(@inscricao.pending_email).to be_nil
      expect(para("ocupado@example.com")).to be_empty
    end

    it "recusa o endereco novo fora do formato, sem deixar pedido pendente" do
      pedir_troca("nova sem formato")

      expect(@sessao.response).to have_http_status(:ok)
      expect(@inscricao.reload.email).to eq("pessoa@example.com")
      expect(@inscricao.pending_email).to be_nil
      expect(@enviados).to be_empty
    end

    it "nao deixa pedido pendente quando o sistema nao esta enviando e-mail" do
      allow(Notifier).to receive(:sending?).and_return(false)

      pedir_troca

      expect(pagina_seguinte(@sessao)).to include(
        ERB::Util.html_escape(I18n.t("admissions.apply.update.email_change_requested_without_email"))
      )
      expect(@inscricao.reload.email).to eq("pessoa@example.com")
      expect(@inscricao.pending_email).to be_nil
      expect(@inscricao.email_change_pending?).to be(false)
    end

    # Controles: a edição que não muda o endereço, e a que só muda a caixa
    # dele, não pedem confirmação nenhuma.
    it "nao pede confirmacao quando a edicao nao muda o e-mail" do
      pedir_troca("pessoa@example.com")

      expect(@inscricao.reload.pending_email).to be_nil
      expect(@enviados.map { |m| m[:to] }).to eq(["pessoa@example.com"])
      expect(link_recebido("pessoa@example.com")).to be_nil
    end

    it "nao pede confirmacao quando so a caixa do e-mail muda" do
      pedir_troca("Pessoa@Example.com")

      expect(@inscricao.reload.email).to eq("Pessoa@Example.com")
      expect(@inscricao.token).to eq(@antigo)
      expect(@inscricao.pending_email).to be_nil
    end
  end

  describe "a confirmacao" do
    before(:each) do
      @antigo = inscrita("pessoa@example.com")
      @inscricao = Admissions::AdmissionApplication.find_by!(token: @antigo)
      @quem_pediu = navegador
      enviar(@quem_pediu, @processo, @antigo, { "Dado" => "dado", "Correio" => "nova@example.com" })
      @link = link_recebido("nova@example.com")
      @enviados.clear
      @quem_confirma = navegador
    end

    it "nao troca nada so por abrir o link" do
      @quem_confirma.get @link

      expect(@quem_confirma.response).to have_http_status(:ok)
      expect(@quem_confirma.response.body).to include("nova@example.com", @inscricao.identifier)
      expect(@quem_confirma.response.body).not_to include(@antigo)
      expect(@inscricao.reload.email).to eq("pessoa@example.com")
      expect(@inscricao.token).to eq(@antigo)
      expect(@inscricao.email_change_pending?).to be(true)
    end

    it "troca o e-mail, renova o codigo, mantem o identificador e manda o codigo novo so ao endereco novo" do
      @quem_confirma.put @link

      @inscricao.reload
      expect(@inscricao.email).to eq("nova@example.com")
      expect(@inscricao.token).not_to eq(@antigo)
      expect(@inscricao.identifier).to eq(@antigo[0, 6])
      expect(@inscricao.pending_email).to be_nil
      expect(@inscricao.email_change_digest).to be_nil
      expect(valor_do_campo(@inscricao, @correio)).to eq("nova@example.com")
      expect(@enviados.map { |m| m[:to] }).to eq(["nova@example.com"])
      expect(codigo_recebido("nova@example.com")).to eq(@inscricao.token)
    end

    it "nao entrega o codigo novo ao navegador que confirmou, so o aviso de para onde ele foi" do
      @quem_confirma.put @link

      destino = @quem_confirma.response.location.to_s
      pagina = pagina_seguinte(@quem_confirma)
      expect(destino + pagina).not_to include(@inscricao.reload.token)
      expect(pagina).to include(
        ERB::Util.html_escape(I18n.t("admissions.email_changes.update.success", email: "nova@example.com"))
      )
    end

    it "faz o codigo antigo deixar de abrir a inscricao, e o novo abrir" do
      @quem_confirma.put @link

      expect(abre?(@quem_pediu, @processo, @antigo)).to be(false)
      expect(abre?(navegador, @processo, @inscricao.reload.token)).to be(true)
    end

    # A ponta do caminho: quem recupera o código pelo e-mail novo recebe um
    # código que só a caixa dele viu.
    it "entrega pela recuperacao, ao endereco novo, o codigo que so a caixa dele viu" do
      @quem_confirma.put @link
      @enviados.clear

      entrar(navegador, @processo, "nova@example.com", "forgot")

      recuperado = codigo_recebido("nova@example.com")
      expect(recuperado).to eq(@inscricao.reload.token)
      expect(recuperado).not_to eq(@antigo)
      entrar(navegador, @processo, "pessoa@example.com", "forgot")
      expect(para("pessoa@example.com")).to be_empty
    end

    it "vale uma vez so" do
      @quem_confirma.put @link
      codigo = @inscricao.reload.token
      @enviados.clear

      outra_vez = navegador
      outra_vez.put @link

      expect(outra_vez.response.location).to end_with(admissions_path)
      expect(outra_vez.flash[:alert]).to eq(I18n.t("errors.admissions.invalid_email_change"))
      expect(@inscricao.reload.token).to eq(codigo)
      expect(@enviados).to be_empty
    end

    it "vence com o prazo do link" do
      travel_to(Time.current + Admissions::AdmissionApplication::EMAIL_CHANGE_VALIDITY + 1.minute) do
        @quem_confirma.get @link
        expect(@quem_confirma.response.location).to end_with(admissions_path)
        expect(@quem_confirma.flash[:alert]).to eq(I18n.t("errors.admissions.invalid_email_change"))

        @quem_confirma.put @link
        expect(@inscricao.reload.email).to eq("pessoa@example.com")
        expect(@inscricao.token).to eq(@antigo)
      end
    end

    # Controle do anterior: um minuto antes do prazo o mesmo link ainda vale.
    it "vale ate o prazo do link" do
      travel_to(Time.current + Admissions::AdmissionApplication::EMAIL_CHANGE_VALIDITY - 1.minute) do
        @quem_confirma.put @link

        expect(@inscricao.reload.email).to eq("nova@example.com")
      end
    end

    it "deixa de valer quando o candidato pede outra troca, e vale o link do pedido novo" do
      enviar(@quem_pediu, @processo, @antigo, { "Dado" => "dado", "Correio" => "outra@example.com" })
      link_novo = link_recebido("outra@example.com")

      @quem_confirma.put @link
      expect(@inscricao.reload.email).to eq("pessoa@example.com")

      @quem_confirma.put link_novo
      expect(@inscricao.reload.email).to eq("outra@example.com")
    end

    it "e recusada quando outra inscricao do processo ocupou o endereco depois do pedido" do
      create_application(@processo, name: "Ocupante", email: "nova@example.com")

      @quem_confirma.put @link

      expect(@quem_confirma.response.location).to end_with(admissions_path)
      expect(@quem_confirma.flash[:alert]).to be_present
      @inscricao.reload
      expect(@inscricao.email).to eq("pessoa@example.com")
      expect(@inscricao.token).to eq(@antigo)
      expect(@inscricao.pending_email).to be_nil
      expect(valor_do_campo(@inscricao, @correio)).to eq("pessoa@example.com")
      expect(@enviados).to be_empty
    end

    it "deixa de valer quando a equipe corrige o e-mail pela tela interna" do
      admin = create_confirmed_user([FactoryBot.create(:role_administrador)], "troca-admin@ic.uff.br", "Admin")
      equipe = navegador
      equipe.post user_session_path, params: { user: { email: admin.email, password: "A1b2c3d4!" } }
      equipe.put admission_application_path(@inscricao), xhr: true, params: {
        can_edit_override: "1", record: { email: "corrigido@example.com" }
      }
      expect(@inscricao.reload.email).to eq("corrigido@example.com")
      expect(@inscricao.pending_email).to be_nil

      @quem_confirma.put @link

      expect(@quem_confirma.flash[:alert]).to eq(I18n.t("errors.admissions.invalid_email_change"))
      expect(@inscricao.reload.email).to eq("corrigido@example.com")
    end

    it "recusa o link que nao existe" do
      @quem_confirma.get admission_email_change_path(id: "codigo-que-nao-existe")
      expect(@quem_confirma.response.location).to end_with(admissions_path)
      expect(@quem_confirma.flash[:alert]).to eq(I18n.t("errors.admissions.invalid_email_change"))

      @quem_confirma.put admission_email_change_path(id: "codigo-que-nao-existe")
      expect(@quem_confirma.response.location).to end_with(admissions_path)
      expect(@inscricao.reload.email).to eq("pessoa@example.com")
    end

    it "diz que o codigo novo nao foi mandado quando o sistema nao esta enviando e-mail" do
      allow(Notifier).to receive(:sending?).and_return(false)

      @quem_confirma.put @link

      expect(@inscricao.reload.email).to eq("nova@example.com")
      expect(pagina_seguinte(@quem_confirma)).to include(
        ERB::Util.html_escape(I18n.t("admissions.email_changes.update.success_without_email"))
      )
    end
  end

  # Em processo com sessão a pré-inscrição nasce com o e-mail da tela do
  # processo, e o formulário pode trazer outro no campo sincronizado: é uma
  # troca como as outras.
  describe "em processo com sessao" do
    before(:each) do
      @sessao = navegador
      @sessao.post admission_path(@com_sessao.simple_url),
        params: { admissions_admission_application: { name: "Pessoa", email: "pessoa@example.com" } }
      @antigo = codigo_recebido("pessoa@example.com")
      entrar(@sessao, @com_sessao, "pessoa@example.com", @antigo)
      enviar(@sessao, @com_sessao, @antigo, { "Dado" => "dado", "Correio" => "nova@example.com" })
      @inscricao = Admissions::AdmissionApplication.find_by!(token: @antigo)
    end

    it "mantem a inscricao aberta no navegador de quem pediu, com o e-mail de antes" do
      expect(@inscricao.email).to eq("pessoa@example.com")
      expect(@inscricao.pending_email).to eq("nova@example.com")
      expect(@inscricao.filled_form.is_filled).to be(true)
      expect(abre?(@sessao, @com_sessao, @antigo)).to be(true)
    end

    it "nao poe o codigo novo na sessao de ninguem ao confirmar" do
      quem_confirma = navegador
      quem_confirma.put link_recebido("nova@example.com")

      novo = @inscricao.reload.token
      expect(novo).not_to eq(@antigo)
      expect(abre?(@sessao, @com_sessao, @antigo)).to be(false)
      expect(abre?(@sessao, @com_sessao, novo)).to be(false)
      expect(abre?(quem_confirma, @com_sessao, novo)).to be(false)
    end
  end
end
