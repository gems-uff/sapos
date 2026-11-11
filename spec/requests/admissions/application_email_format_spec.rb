# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O e-mail da inscrição é para onde o código de identificação viaja, e o do
# pedido de carta, para onde vai o link do recomendador. Texto que não é
# endereço deixa o candidato sem o código e o recomendador sem o link (issue
# #751). O navegador confere o formato no campo de e-mail da tela; o servidor
# confere de novo, porque o envio pode não vir da tela e porque o campo do
# formulário sincronizado com o e-mail é uma caixa de texto.
RSpec.describe "Formato do e-mail da inscricao", type: :request do
  NAO_SAO_ENDERECOS = {
    "sem arroba" => "pessoa.example.com",
    "com espaco no meio" => "pessoa @example.com",
    "que e uma lista" => "pessoa@example.com, outra@example.com",
    "sem dominio" => "pessoa@",
  }.freeze

  before(:each) do
    @enviados = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviados.concat(notifications) }
    allow(ExceptionNotifier).to receive(:notify_exception)

    @template = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    @sincronizado = create_admission_template(
      "Com e-mail", { "Dado" => Admissions::FormField::STRING, "Correio" => Admissions::FormField::STRING }
    )
    @sincronizado.fields.find_by!(name: "Correio").update!(sync: Admissions::FormField::SYNC_EMAIL)
    datas = {
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    }
    @com_sessao = FactoryBot.create(
      :admission_process, name: "Com sessao", simple_url: "formato-com-sessao",
      form_template: @template, require_session: true, **datas
    )
    @sem_sessao = FactoryBot.create(
      :admission_process, name: "Sem sessao", simple_url: "formato-sem-sessao",
      form_template: @template, require_session: false, **datas
    )
    @com_campo = FactoryBot.create(
      :admission_process, name: "Com campo de e-mail", simple_url: "formato-com-campo",
      form_template: @sincronizado, require_session: false, **datas
    )
  end

  # Nome e e-mail na tela do processo.
  def pedir(processo, nome, email)
    post admission_path(processo.simple_url),
      params: { admissions_admission_application: { name: nome, email: email } }
  end

  def campos(template, inscricao, valores)
    template.fields.order(:id).each_with_index.to_h do |campo, i|
      entrada = { form_field_id: campo.id, value: valores[campo.name] }
      existente = inscricao&.filled_form&.fields&.find_by(form_field_id: campo.id)
      entrada[:id] = existente.id if existente
      [i.to_s, entrada]
    end
  end

  # Envio do formulário que cria a inscrição, em processo sem sessão.
  def inscrever(processo, valores, **extra)
    post admission_apply_index_path(admission_id: processo.simple_id), params: { record: {
      filled_form_attributes: {
        enable_submission: "1", fields_attributes: campos(processo.form_template, nil, valores),
      }, **extra,
    } }
  end

  # Envio do formulário de uma inscrição que já existe.
  def enviar(processo, inscricao, valores, **extra)
    put admission_apply_path(admission_id: processo.simple_id, id: inscricao.token), params: { record: {
      filled_form_attributes: {
        id: inscricao.filled_form.id, enable_submission: "1",
        fields_attributes: campos(processo.form_template, inscricao, valores),
      }, **extra,
    } }
  end

  def recusa_do_formato
    ERB::Util.html_escape(
      "#{Admissions::AdmissionApplication.human_attribute_name(:email)} #{I18n.t('errors.messages.invalid')}"
    )
  end

  describe "na pre-inscricao" do
    NAO_SAO_ENDERECOS.each do |caso, texto|
      it "recusa o texto #{caso}, sem criar a inscricao nem mandar mensagem" do
        expect {
          pedir(@com_sessao, "Pessoa", texto)
        }.not_to change { Admissions::AdmissionApplication.count }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(recusa_do_formato)
        expect(@enviados).to be_empty
      end
    end

    # Controle: o endereço é aceito, e o código segue para ele.
    it "aceita o endereco" do
      expect {
        pedir(@com_sessao, "Pessoa", "pessoa@example.com")
      }.to change { Admissions::AdmissionApplication.count }.by(1)
      expect(@enviados.map { |mensagem| mensagem[:to] }).to eq(["pessoa@example.com"])
    end

    # O espaço em volta não é parte do endereço: sai antes de gravar.
    it "aceita o endereco com espaco em volta, e o grava sem o espaco" do
      pedir(@com_sessao, "Pessoa", "  pessoa@example.com ")

      expect(Admissions::AdmissionApplication.find_by(admission_process: @com_sessao)&.email).to eq("pessoa@example.com")
    end
  end

  describe "no formulario que cria a inscricao" do
    NAO_SAO_ENDERECOS.each do |caso, texto|
      it "recusa no campo de e-mail da tela o texto #{caso}" do
        expect {
          inscrever(@sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: texto)
        }.not_to change { Admissions::AdmissionApplication.count }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(recusa_do_formato)
        expect(@enviados).to be_empty
      end

      it "recusa no campo sincronizado com o e-mail o texto #{caso}" do
        expect {
          inscrever(@com_campo, { "Dado" => "dado", "Correio" => texto }, name: "Pessoa")
        }.not_to change { Admissions::AdmissionApplication.count }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(recusa_do_formato)
        expect(@enviados).to be_empty
      end
    end

    # Controles: o mesmo envio, com endereço.
    it "aceita o endereco no campo de e-mail da tela" do
      inscrever(@sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: "pessoa@example.com")

      expect(Admissions::AdmissionApplication.find_by(email: "pessoa@example.com")&.filled_form&.is_filled).to be(true)
    end

    it "aceita o endereco no campo sincronizado com o e-mail" do
      inscrever(@com_campo, { "Dado" => "dado", "Correio" => "pessoa@example.com" }, name: "Pessoa")

      expect(Admissions::AdmissionApplication.find_by(email: "pessoa@example.com")&.filled_form&.is_filled).to be(true)
    end

    # O campo sincronizado é conferido também pelo navegador, como o campo de
    # e-mail da tela.
    it "oferece o campo sincronizado como campo de e-mail" do
      get new_admission_apply_path(admission_id: @com_campo.simple_id)

      correio = @sincronizado.fields.find_by!(name: "Correio")
      pagina = Nokogiri::HTML(response.body)
      marca = pagina.css("input[type=hidden][name$='[form_field_id]']").find { |e| e["value"] == correio.id.to_s }
      campo = pagina.at_css("input[name='#{marca['name'].delete_suffix('[form_field_id]')}[value]']")

      expect(campo["type"]).to eq("email")
    end
  end

  # Nos modelos em uso, o campo sincronizado com o e-mail costuma ser um campo
  # de aluno (o e-mail do aluno que a candidatura vira), e não um texto simples.
  describe "quando o campo sincronizado com o e-mail e um campo de aluno" do
    before(:each) do
      @de_aluno = create_admission_template("Com e-mail de aluno", {
        "Dado" => Admissions::FormField::STRING,
        "Correio" => {
          field_type: Admissions::FormField::STUDENT_FIELD, configuration: { field: "email" },
          sync: Admissions::FormField::SYNC_EMAIL,
        },
      })
      @com_campo.update!(form_template: @de_aluno)
    end

    it "oferece o campo como campo de e-mail" do
      get new_admission_apply_path(admission_id: @com_campo.simple_id)

      correio = @de_aluno.fields.find_by!(name: "Correio")
      pagina = Nokogiri::HTML(response.body)
      marca = pagina.css("input[type=hidden][name$='[form_field_id]']").find { |e| e["value"] == correio.id.to_s }
      campo = pagina.at_css("input[name='#{marca['name'].delete_suffix('[form_field_id]')}[value]']")

      expect(campo["type"]).to eq("email")
    end

    it "recusa o texto que nao e endereco" do
      expect {
        inscrever(@com_campo, { "Dado" => "dado", "Correio" => "pessoa.example.com" }, name: "Pessoa")
      }.not_to change { Admissions::AdmissionApplication.count }

      expect(response.body).to include(recusa_do_formato)
    end

    # Controle: o mesmo envio, com endereço.
    it "aceita o endereco" do
      inscrever(@com_campo, { "Dado" => "dado", "Correio" => "pessoa@example.com" }, name: "Pessoa")

      expect(Admissions::AdmissionApplication.find_by(email: "pessoa@example.com")&.filled_form&.is_filled).to be(true)
    end
  end

  # Inscrição gravada antes da conferência pode ter endereço fora do formato.
  # O candidato tem de conseguir editar o resto; a conferência vale para o
  # endereço novo ou alterado.
  describe "na inscricao que ja tem endereco fora do formato" do
    before(:each) do
      @inscricao = create_application(@sem_sessao, name: "Antiga", email: "antiga@example.com", fields: { "Dado" => "dado" })
      @inscricao.update_column(:email, "antiga sem formato")
    end

    it "deixa o candidato editar os outros campos" do
      enviar(@sem_sessao, @inscricao, { "Dado" => "outro dado" })

      expect(response).to redirect_to(admission_apply_path(admission_id: @sem_sessao.simple_id, id: @inscricao.token))
      expect(@inscricao.reload.filled_form.fields.first.value).to eq("outro dado")
      expect(@inscricao.email).to eq("antiga sem formato")
    end

    # O campo de e-mail do navegador não deixa enviar o formulário enquanto o
    # valor não é endereço, e o valor gravado já vem nele: a inscrição ficaria
    # sem poder editar campo nenhum.
    context "no campo sincronizado com o e-mail" do
      def tipo_do_campo(inscricao)
        get edit_admission_apply_path(admission_id: @com_campo.simple_id, id: inscricao.token)
        correio = @sincronizado.fields.find_by!(name: "Correio")
        pagina = Nokogiri::HTML(response.body)
        marca = pagina.css("input[type=hidden][name$='[form_field_id]']").find { |e| e["value"] == correio.id.to_s }
        pagina.at_css("input[name='#{marca['name'].delete_suffix('[form_field_id]')}[value]']")["type"]
      end

      def inscricao_com(endereco)
        inscricao = create_application(
          @com_campo, name: "Antiga", email: "antiga@example.com", fields: { "Dado" => "dado", "Correio" => endereco }
        )
        inscricao.update_column(:email, endereco)
        inscricao
      end

      it "oferece como texto o endereco gravado fora do formato" do
        expect(tipo_do_campo(inscricao_com("antiga sem formato"))).to eq("text")
      end

      it "oferece como texto o endereco gravado fora do formato, quando o campo e de aluno" do
        de_aluno = create_admission_template("Com e-mail de aluno", {
          "Dado" => Admissions::FormField::STRING,
          "Correio" => {
            field_type: Admissions::FormField::STUDENT_FIELD, configuration: { field: "email" },
            sync: Admissions::FormField::SYNC_EMAIL,
          },
        })
        @com_campo.update!(form_template: de_aluno)
        @sincronizado = de_aluno

        expect(tipo_do_campo(inscricao_com("antiga sem formato"))).to eq("text")
      end

      # O navegador tira o espaço em volta antes de conferir.
      it "oferece como campo de e-mail o endereco gravado com espaco em volta" do
        expect(tipo_do_campo(inscricao_com("antiga@example.com "))).to eq("email")
      end

      # Controle: o endereço gravado no formato.
      it "oferece como campo de e-mail o endereco gravado no formato" do
        expect(tipo_do_campo(inscricao_com("antiga@example.com"))).to eq("email")
      end
    end

    # A tela antiga gravava o endereço como digitado, com o espaço em volta. O
    # espaço não faz do endereço gravado um endereço alterado.
    context "e com espaco em volta" do
      before(:each) do
        @inscricao.update_column(:email, "antiga@example.com. ")
      end

      it "deixa o candidato editar os outros campos" do
        enviar(@sem_sessao, @inscricao, { "Dado" => "outro dado" })

        expect(response).to redirect_to(admission_apply_path(admission_id: @sem_sessao.simple_id, id: @inscricao.token))
        expect(@inscricao.reload.filled_form.fields.first.value).to eq("outro dado")
      end

      it "deixa a equipe gravar o que nao e o e-mail" do
        expect(@inscricao.reload.update(status: Admissions::AdmissionApplication::CANCELED)).to be(true)
      end

      it "deixa o candidato pedir a troca pelo campo sincronizado com o e-mail" do
        inscricao = create_application(
          @com_campo, name: "Antiga", email: "antiga@example.com",
          fields: { "Dado" => "dado", "Correio" => "antiga@example.com. " }
        )
        inscricao.update_column(:email, "antiga@example.com. ")

        enviar(@com_campo, inscricao, { "Dado" => "dado", "Correio" => "certa@example.com" })

        expect(response).to redirect_to(admission_apply_path(admission_id: @com_campo.simple_id, id: inscricao.token))
        expect(inscricao.reload.pending_email).to eq("certa@example.com")
      end

      # Controle: o endereço alterado continua conferido.
      it "recusa o endereco alterado que continua fora do formato" do
        expect(@inscricao.reload.update(email: "outra sem formato")).to be(false)
      end
    end
  end

  # O processo deixava mais de uma inscrição por e-mail e deixou de deixar: as
  # que já repetiam o endereço continuam editáveis, e a saída do candidato é
  # trocar o endereço.
  describe "na inscricao que repete o e-mail de outra do processo" do
    before(:each) do
      @com_campo.update!(allow_multiple_applications: true)
      valores = { "Dado" => "dado", "Correio" => "repetido@example.com" }
      create_application(@com_campo, name: "Primeira", email: "repetido@example.com", fields: valores)
      @inscricao = create_application(@com_campo, name: "Segunda", email: "repetido@example.com", fields: valores)
      @com_campo.update!(allow_multiple_applications: false)
    end

    it "deixa o candidato editar os outros campos" do
      enviar(@com_campo, @inscricao, { "Dado" => "outro dado", "Correio" => "repetido@example.com" })

      expect(response).to redirect_to(admission_apply_path(admission_id: @com_campo.simple_id, id: @inscricao.token))
      expect(@inscricao.reload.fields_hash["Dado"].value).to eq("outro dado")
    end

    it "deixa o candidato pedir a troca do endereco" do
      enviar(@com_campo, @inscricao, { "Dado" => "dado", "Correio" => "proprio@example.com" })

      expect(response).to redirect_to(admission_apply_path(admission_id: @com_campo.simple_id, id: @inscricao.token))
      expect(@inscricao.reload.pending_email).to eq("proprio@example.com")
    end

    # Controle: o endereço novo não pode ser o de outra inscrição do processo.
    it "recusa a troca para o endereco de outra inscricao" do
      create_application(@com_campo, name: "Terceira", email: "ocupado@example.com")

      enviar(@com_campo, @inscricao, { "Dado" => "dado", "Correio" => "ocupado@example.com" })

      expect(response).to have_http_status(:ok)
      expect(@inscricao.reload.pending_email).to be_nil
    end
  end

  # O endereço maior que a coluna passa no formato e estoura no banco de
  # produção, que não trunca; no SQLite da suíte ele seria gravado.
  describe "no endereco maior que a coluna do banco" do
    it "recusa na pre-inscricao, sem criar a inscricao" do
      expect {
        pedir(@com_sessao, "Pessoa", "#{'a' * 250}@example.com")
      }.not_to change { Admissions::AdmissionApplication.count }

      expect(response.body).to include(ERB::Util.html_escape(Admissions::AdmissionApplication.human_attribute_name(:email)))
    end

    it "recusa no pedido de carta" do
      pedido = Admissions::LetterRequest.new(
        admission_application: create_application(@sem_sessao), name: "Recomendador",
        email: "#{'a' * 250}@example.com"
      )

      expect(pedido).not_to be_valid
      expect(pedido.errors.where(:email, :too_long)).to be_present
    end

    # Controle: o endereço do tamanho da coluna entra.
    it "aceita o endereco do tamanho da coluna" do
      expect {
        pedir(@com_sessao, "Pessoa", "#{'a' * 243}@example.com")
      }.to change { Admissions::AdmissionApplication.count }.by(1)
    end
  end

  describe "no e-mail do recomendador" do
    before(:each) do
      letter_template = FactoryBot.create(:form_template, name: "Carta", template_type: "Carta de Recomendação")
      @sem_sessao.update!(letter_template: letter_template, min_letters: 0, max_letters: 2)
      @inscricao = create_application(@sem_sessao, name: "Pessoa", email: "pessoa@example.com", fields: { "Dado" => "dado" })
    end

    def pedir_carta(email)
      enviar(
        @sem_sessao, @inscricao, { "Dado" => "dado" },
        letter_requests_attributes: { "0" => { name: "Recomendador", email: email } }
      )
    end

    NAO_SAO_ENDERECOS.each do |caso, texto|
      it "recusa o texto #{caso}, sem criar o pedido de carta nem mandar o link" do
        expect { pedir_carta(texto) }.not_to change { Admissions::LetterRequest.count }

        expect(response).to have_http_status(:ok)
        expect(@enviados).to be_empty
      end
    end

    # O pedido gravado antes da conferência, com endereço fora do formato e
    # espaço em volta: a página da carta nem mostra o endereço.
    it "deixa o recomendador responder a carta do pedido com endereco fora do formato" do
      pedido = Admissions::LetterRequest.create!(
        admission_application: @inscricao, name: "Recomendador", email: "recomendador@example.com"
      )
      pedido.update_column(:email, "recomendador@example.com. ")

      put admission_letter_path(admission_id: @sem_sessao.simple_id, id: pedido.access_token), params: { record: {
        filled_form_attributes: { id: pedido.filled_form.id, enable_submission: "1" },
      } }

      expect(response).to redirect_to(admissions_path)
      expect(pedido.reload.is_filled).to be(true)
    end

    # Controle: o mesmo pedido, com endereço.
    it "aceita o endereco e manda o link" do
      expect { pedir_carta("recomendador@example.com") }.to change { Admissions::LetterRequest.count }.by(1)

      expect(@enviados.map { |mensagem| mensagem[:to] }).to include("recomendador@example.com")
    end
  end
end
