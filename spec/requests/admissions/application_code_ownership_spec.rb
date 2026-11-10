# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O código de identificação é a credencial da inscrição, e o e-mail não é
# segredo. Estes exemplos percorrem o que acontece quando dois navegadores
# apresentam o mesmo e-mail: quem chega depois não herda o código de quem
# chegou antes, e quem chegou antes não fica com um código que ainda vale.
RSpec.describe "Posse do codigo de inscricao", type: :request do
  before(:each) do
    @template = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    datas = {
      start_date: Date.current - 10.days, end_date: Date.current + 10.days, edit_date: Date.current + 20.days
    }
    @com_sessao = FactoryBot.create(
      :admission_process, name: "Com sessao", simple_url: "posse-com-sessao",
      form_template: @template, require_session: true, **datas
    )
    @sem_sessao = FactoryBot.create(
      :admission_process, name: "Sem sessao", simple_url: "posse-sem-sessao",
      form_template: @template, require_session: false, **datas
    )
  end

  def navegador
    open_session.tap { |sessao| sessao.host! "www.example.com" }
  end

  # Nome e e-mail na tela do processo; devolve o código para onde o navegador
  # foi levado.
  def entrar(sessao, processo, nome, email, **extra)
    sessao.post admission_path(processo.simple_url),
      params: { admissions_admission_application: { name: nome, email: email, **extra } }
    sessao.response.location.to_s[%r{/apply/([^/?]+)}, 1]
  end

  def enviar(sessao, processo, codigo, valor)
    inscricao = Admissions::AdmissionApplication.find_by!(token: codigo)
    sessao.put admission_apply_path(admission_id: processo.simple_id, id: codigo), params: { record: {
      filled_form_attributes: {
        id: inscricao.filled_form.id, enable_submission: "1",
        fields_attributes: { "0" => { form_field_id: @template.fields.first.id, value: valor } },
      },
    } }
  end

  def abre?(sessao, processo, codigo)
    sessao.get admission_apply_path(admission_id: processo.simple_id, id: codigo)
    sessao.response.successful?
  end

  describe "pre-inscricao retomada pelo e-mail" do
    it "troca o codigo quando a retomada vem de outro navegador" do
      primeiro, segundo = navegador, navegador
      codigo_do_primeiro = entrar(primeiro, @com_sessao, "Primeiro", "pessoa@example.com")

      codigo_do_segundo = nil
      expect {
        codigo_do_segundo = entrar(segundo, @com_sessao, "Segundo", "pessoa@example.com")
      }.not_to change { Admissions::AdmissionApplication.count }

      expect(codigo_do_segundo).to be_present
      expect(codigo_do_segundo).not_to eq(codigo_do_primeiro)
      expect(Admissions::AdmissionApplication.exists?(token: codigo_do_primeiro)).to be(false)
    end

    it "nao deixa quem chegou antes ler nem alterar a inscricao enviada depois" do
      primeiro, segundo = navegador, navegador
      codigo_do_primeiro = entrar(primeiro, @com_sessao, "Primeiro", "pessoa@example.com")
      codigo_do_segundo = entrar(segundo, @com_sessao, "Segundo", "pessoa@example.com")
      enviar(segundo, @com_sessao, codigo_do_segundo, "dado de quem enviou")

      expect(abre?(primeiro, @com_sessao, codigo_do_primeiro)).to be(false)
      expect(abre?(primeiro, @com_sessao, codigo_do_segundo)).to be(false)
      primeiro.put admission_apply_path(admission_id: @com_sessao.simple_id, id: codigo_do_primeiro),
        params: { record: { name: "Adulterado" } }
      inscricao = Admissions::AdmissionApplication.find_by!(token: codigo_do_segundo)
      expect(inscricao.name).to eq("Segundo")
      expect(inscricao.filled_form.fields.first.value).to eq("dado de quem enviou")
    end

    # Controle: o mesmo navegador volta à tela do processo e continua de onde
    # parou, com o mesmo código — e é quem chegou depois que lê o que enviou.
    it "mantem o codigo quando a retomada vem do mesmo navegador" do
      sessao = navegador
      codigo = entrar(sessao, @com_sessao, "Pessoa", "pessoa@example.com")

      expect(entrar(sessao, @com_sessao, "Pessoa Silva", "pessoa@example.com")).to eq(codigo)
      enviar(sessao, @com_sessao, codigo, "dado de quem enviou")
      expect(abre?(sessao, @com_sessao, codigo)).to be(true)
      expect(sessao.response.body).to include("dado de quem enviou")
    end
  end

  describe "o que a tela do processo nao manda" do
    it "nao aceita o codigo escolhido por quem se inscreve" do
      codigo = entrar(navegador, @com_sessao, "Pessoa", "pessoa@example.com", token: "CODIGO-ESCOLHIDO")

      expect(codigo).to be_present
      expect(codigo).not_to eq("CODIGO-ESCOLHIDO")
      expect(Admissions::AdmissionApplication.exists?(token: "CODIGO-ESCOLHIDO")).to be(false)
    end

    it "nao quebra com a origem do formulario de recuperacao" do
      codigo = entrar(navegador, @com_sessao, "Pessoa", "pessoa@example.com", _source: "qualquer")

      expect(codigo).to be_present
    end
  end

  describe "processo que nao pede sessao" do
    it "nao cria pre-inscricao pela tela do processo, e leva ao formulario" do
      sessao = navegador

      expect {
        entrar(sessao, @sem_sessao, "Pessoa", "pessoa@example.com")
      }.not_to change { Admissions::AdmissionApplication.count }
      expect(sessao.response.location).to end_with(new_admission_apply_path(admission_id: @sem_sessao.simple_id))
    end

    # Controle: sem a pré-inscrição de outra pessoa no caminho, o formulário
    # aceita o e-mail.
    it "aceita a inscricao pelo formulario depois da tentativa de outra pessoa com o mesmo e-mail" do
      entrar(navegador, @sem_sessao, "Outra pessoa", "pessoa@example.com")
      sessao = navegador

      sessao.post admission_apply_index_path(admission_id: @sem_sessao.simple_id), params: { record: {
        name: "Pessoa", email: "pessoa@example.com",
        filled_form_attributes: {
          enable_submission: "1",
          fields_attributes: { "0" => { form_field_id: @template.fields.first.id, value: "dado" } },
        },
      } }

      inscricao = Admissions::AdmissionApplication.find_by(email: "pessoa@example.com")
      expect(inscricao&.name).to eq("Pessoa")
      expect(inscricao.filled_form.is_filled).to be(true)
    end
  end

  describe "geracao do codigo" do
    it "sorteia cada caractere pelo gerador criptografico" do
      allow(SecureRandom).to receive(:rand).and_call_original

      inscricao = create_application(@com_sessao, name: "Pessoa")

      expect(inscricao.token).to match(/\A[2346789BCDFGHJKMPQRTVWXY]{6}-[2346789BCDFGHJKMPQRTVWXY]{6}-[2346789BCDFGHJKMPQRTVWXY]{6}\z/)
      expect(SecureRandom).to have_received(:rand).at_least(18).times
    end
  end
end
