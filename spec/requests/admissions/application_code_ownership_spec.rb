# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O código de identificação é a credencial da inscrição, e o e-mail não é
# segredo. A regra que estes exemplos cobram é uma só: o código só viaja por
# e-mail, para o endereço da inscrição. O navegador que pede a inscrição recebe
# o aviso de para onde o código foi, nunca o código; quem o apresenta depois
# leu a caixa daquele endereço. Quando o endereço muda, o código muda junto --
# e o endereço só muda, a pedido do candidato, depois de confirmado pela caixa
# nova (application_email_change_spec.rb).
RSpec.describe "Posse do codigo de inscricao", type: :request do
  # O formato do código: três blocos de seis caracteres do alfabeto do gerador.
  def formato_do_codigo
    /[2346789BCDFGHJKMPQRTVWXY]{6}-[2346789BCDFGHJKMPQRTVWXY]{6}-[2346789BCDFGHJKMPQRTVWXY]{6}/
  end

  before(:each) do
    @enviados = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviados.concat(notifications) }

    @template = create_admission_template("Inscricao", { "Dado" => Admissions::FormField::STRING })
    @sincronizado = create_admission_template(
      "Com e-mail", { "Dado" => Admissions::FormField::STRING, "Correio" => Admissions::FormField::STRING }
    )
    @sincronizado.fields.find_by!(name: "Correio").update!(sync: Admissions::FormField::SYNC_EMAIL)
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
    @com_campo = FactoryBot.create(
      :admission_process, name: "Com campo de e-mail", simple_url: "posse-com-campo",
      form_template: @sincronizado, require_session: false, **datas
    )
  end

  def navegador
    open_session.tap { |sessao| sessao.host! "www.example.com" }
  end

  # Nome e e-mail na tela do processo.
  def pedir(sessao, processo, nome, email, **extra)
    sessao.post admission_path(processo.simple_url),
      params: { admissions_admission_application: { name: nome, email: email, **extra } }
  end

  # O código que a última mensagem para o endereço traz.
  def codigo_recebido(email)
    @enviados.reverse.find { |mensagem| mensagem[:to] == email }&.dig(:body)&.slice(formato_do_codigo)
  end

  # E-mail e código no formulário de recuperação da tela do processo.
  def entrar(sessao, processo, email, codigo)
    sessao.post find_admissions_path, params: {
      admissions_admission_application: { email: email, token: codigo, _source: processo.simple_id },
    }
  end

  def campos(template, inscricao, valores)
    template.fields.order(:id).each_with_index.to_h do |campo, i|
      entrada = { form_field_id: campo.id, value: valores[campo.name] }
      existente = inscricao&.filled_form&.fields&.find_by(form_field_id: campo.id)
      entrada[:id] = existente.id if existente
      [i.to_s, entrada]
    end
  end

  # Envio do formulário de uma inscrição que já existe.
  def enviar(sessao, processo, codigo, valores, **extra)
    inscricao = Admissions::AdmissionApplication.find_by!(token: codigo)
    sessao.put admission_apply_path(admission_id: processo.simple_id, id: codigo), params: { record: {
      filled_form_attributes: {
        id: inscricao.filled_form.id, enable_submission: "1",
        fields_attributes: campos(processo.form_template, inscricao, valores),
      }, **extra,
    } }
  end

  # Envio do formulário que cria a inscrição, em processo sem sessão.
  def inscrever(sessao, processo, valores, **extra)
    sessao.post admission_apply_index_path(admission_id: processo.simple_id), params: { record: {
      filled_form_attributes: {
        enable_submission: "1", fields_attributes: campos(processo.form_template, nil, valores),
      }, **extra,
    } }
  end

  def abre?(sessao, processo, codigo)
    sessao.get admission_apply_path(admission_id: processo.simple_id, id: codigo)
    sessao.response.successful?
  end

  # O que o navegador recebeu de volta: para onde foi mandado e a página a que
  # chegou.
  def resposta_inteira(sessao)
    destino = sessao.response.location.to_s
    sessao.follow_redirect! if sessao.response.redirect?
    destino + sessao.response.body
  end

  describe "pre-inscricao, em processo com sessao" do
    it "manda o codigo para o e-mail e nao o entrega ao navegador" do
      sessao = navegador

      expect {
        pedir(sessao, @com_sessao, "Pessoa", "pessoa@example.com")
      }.to change { Admissions::AdmissionApplication.count }.by(1)

      inscricao = Admissions::AdmissionApplication.find_by!(email: "pessoa@example.com")
      expect(sessao.response.location).to end_with(
        admission_path(id: @com_sessao.simple_id, email: "pessoa@example.com")
      )
      expect(resposta_inteira(sessao)).not_to include(inscricao.token)
      expect(sessao.response.body).to include(
        ERB::Util.html_escape(I18n.t("admissions.admissions.create.token_sent", email: "pessoa@example.com"))
      )
      expect(abre?(sessao, @com_sessao, inscricao.token)).to be(false)
      expect(@enviados.map { |mensagem| mensagem[:to] }).to eq(["pessoa@example.com"])
      expect(codigo_recebido("pessoa@example.com")).to eq(inscricao.token)
    end

    it "nao deixa quem so apresentou o e-mail ler nem alterar a inscricao enviada depois" do
      primeiro, segundo = navegador, navegador
      pedir(primeiro, @com_sessao, "Primeiro", "pessoa@example.com")
      expect(primeiro.response.location).not_to match(formato_do_codigo)

      expect {
        pedir(segundo, @com_sessao, "Segundo", "pessoa@example.com")
      }.not_to change { Admissions::AdmissionApplication.count }
      codigo = codigo_recebido("pessoa@example.com")
      entrar(segundo, @com_sessao, "pessoa@example.com", codigo)
      enviar(segundo, @com_sessao, codigo, { "Dado" => "dado de quem enviou" })

      expect(abre?(primeiro, @com_sessao, codigo)).to be(false)
      enviar(primeiro, @com_sessao, codigo, { "Dado" => "adulterado" })
      inscricao = Admissions::AdmissionApplication.find_by!(token: codigo)
      expect(inscricao.filled_form.fields.first.value).to eq("dado de quem enviou")
    end

    # Reenviar não troca o código: quem já está preenchendo o formulário, neste
    # ou noutro aparelho, não o perde porque o e-mail foi apresentado de novo.
    it "reenvia o mesmo codigo quando o e-mail e apresentado de novo, sem tocar a pre-inscricao" do
      pedir(navegador, @com_sessao, "Pessoa", "pessoa@example.com")
      codigo = codigo_recebido("pessoa@example.com")
      @enviados.clear

      pedir(navegador, @com_sessao, "Outro nome", "pessoa@example.com")

      expect(codigo_recebido("pessoa@example.com")).to eq(codigo)
      expect(Admissions::AdmissionApplication.find_by!(token: codigo).name).to eq("Pessoa")
    end

    # Controle: com o código da mensagem, o formulário abre e a inscrição
    # enviada aparece para quem a enviou.
    it "leva ao formulario quem apresenta o e-mail e o codigo recebido" do
      sessao = navegador
      pedir(sessao, @com_sessao, "Pessoa", "pessoa@example.com")
      codigo = codigo_recebido("pessoa@example.com")

      entrar(sessao, @com_sessao, "pessoa@example.com", codigo)
      expect(sessao.response.location).to end_with(
        edit_admission_apply_path(admission_id: @com_sessao.simple_id, id: codigo)
      )
      enviar(sessao, @com_sessao, codigo, { "Dado" => "dado de quem enviou" })
      expect(sessao.response.location).to end_with(
        admission_apply_path(admission_id: @com_sessao.simple_id, id: codigo)
      )
      expect(abre?(sessao, @com_sessao, codigo)).to be(true)
      expect(sessao.response.body).to include("dado de quem enviou")
    end

    # Controle: o navegador que já entrou com o código volta à tela do processo
    # e continua de onde parou, sem outra mensagem.
    it "continua no formulario quando o navegador ja entrou com o codigo" do
      sessao = navegador
      pedir(sessao, @com_sessao, "Pessoa", "pessoa@example.com")
      codigo = codigo_recebido("pessoa@example.com")
      entrar(sessao, @com_sessao, "pessoa@example.com", codigo)
      @enviados.clear

      pedir(sessao, @com_sessao, "Pessoa Silva", "pessoa@example.com")

      expect(sessao.response.location).to end_with(
        edit_admission_apply_path(admission_id: @com_sessao.simple_id, id: codigo)
      )
      expect(Admissions::AdmissionApplication.find_by!(token: codigo).name).to eq("Pessoa Silva")
      expect(@enviados).to be_empty
    end
  end

  # Em produção a tela do processo confere o reCAPTCHA; a suíte o desliga. A
  # tela que volta depois da recusa não pode trazer a pré-inscrição que o
  # e-mail digitado encontrou.
  describe "captcha recusado na tela do processo" do
    before(:each) do
      allow(Rails.application.config).to receive(:should_use_recaptcha).and_return(true)
      allow_any_instance_of(Admissions::AdmissionsController).to receive(:verify_recaptcha).and_return(false)
      allow_any_instance_of(ActionView::Base).to receive(:recaptcha_tags).and_return("")
    end

    it "nao devolve o codigo nem o nome da pre-inscricao de quem ja usou o e-mail" do
      existente = create_application(@com_sessao, name: "Dono Da Inscricao", email: "pessoa@example.com", filled: false)
      sessao = navegador

      pedir(sessao, @com_sessao, "Outra Pessoa", "pessoa@example.com")

      expect(sessao.response).to have_http_status(:ok)
      expect(sessao.response.body).not_to include(existente.token)
      expect(sessao.response.body).not_to include("Dono Da Inscricao")
      expect(@enviados).to be_empty
    end

    # Controle: a tela volta com o que quem pediu digitou.
    it "volta com o nome e o e-mail digitados" do
      sessao = navegador

      pedir(sessao, @com_sessao, "Outra Pessoa", "pessoa@example.com")

      expect(sessao.response.body).to include('value="Outra Pessoa"', 'value="pessoa@example.com"')
    end
  end

  describe "o que a tela do processo nao manda" do
    it "nao aceita o codigo escolhido por quem se inscreve" do
      pedir(navegador, @com_sessao, "Pessoa", "pessoa@example.com", token: "CODIGO-ESCOLHIDO")

      inscricao = Admissions::AdmissionApplication.find_by!(email: "pessoa@example.com")
      expect(inscricao.token.sub(formato_do_codigo, "")).to eq("")
      expect(Admissions::AdmissionApplication.exists?(token: "CODIGO-ESCOLHIDO")).to be(false)
    end

    it "nao aceita o codigo de outra inscricao" do
      outra = create_application(@sem_sessao, name: "Outra", email: "outra@example.com")

      pedir(navegador, @com_sessao, "Pessoa", "pessoa@example.com", token: outra.token)

      expect(Admissions::AdmissionApplication.where(token: outra.token).count).to eq(1)
    end

    it "nao quebra com a origem do formulario de recuperacao" do
      pedir(navegador, @com_sessao, "Pessoa", "pessoa@example.com", _source: "qualquer")

      expect(Admissions::AdmissionApplication.exists?(email: "pessoa@example.com")).to be(true)
    end
  end

  describe "processo que nao pede sessao" do
    it "nao cria pre-inscricao pela tela do processo, e leva ao formulario" do
      sessao = navegador

      expect {
        pedir(sessao, @sem_sessao, "Pessoa", "pessoa@example.com")
      }.not_to change { Admissions::AdmissionApplication.count }
      expect(sessao.response.location).to end_with(new_admission_apply_path(admission_id: @sem_sessao.simple_id))
    end

    # Controle: sem a pré-inscrição de outra pessoa no caminho, o formulário
    # aceita o e-mail.
    it "aceita a inscricao pelo formulario depois da tentativa de outra pessoa com o mesmo e-mail" do
      pedir(navegador, @sem_sessao, "Outra pessoa", "pessoa@example.com")

      inscrever(navegador, @sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: "pessoa@example.com")

      inscricao = Admissions::AdmissionApplication.find_by(email: "pessoa@example.com")
      expect(inscricao&.name).to eq("Pessoa")
      expect(inscricao.filled_form.is_filled).to be(true)
    end

    it "manda o codigo para o e-mail informado e nao o entrega a quem enviou o formulario" do
      sessao = navegador

      inscrever(sessao, @sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: "pessoa@example.com")

      inscricao = Admissions::AdmissionApplication.find_by!(email: "pessoa@example.com")
      expect(sessao.response.location).to end_with(admissions_path)
      expect(resposta_inteira(sessao)).not_to include(inscricao.token)
      expect(sessao.response.body).to include(
        ERB::Util.html_escape(I18n.t("admissions.apply.update.new_token_sent", email: "pessoa@example.com"))
      )
      expect(codigo_recebido("pessoa@example.com")).to eq(inscricao.token)
    end

    # Controle: o link da mensagem abre a inscrição, de qualquer navegador.
    it "abre a inscricao pelo link que a mensagem traz" do
      inscrever(navegador, @sem_sessao, { "Dado" => "dado de quem enviou" }, name: "Pessoa", email: "pessoa@example.com")
      mensagem = @enviados.find { |m| m[:to] == "pessoa@example.com" }
      link = mensagem[:body][%r{https?://\S+/apply/\S+}]

      outro = navegador
      outro.get URI(link).path

      expect(outro.response).to be_successful
      expect(outro.response.body).to include("dado de quem enviou")
    end
  end

  describe "troca do e-mail da inscricao" do
    def inscrita(processo, valores, **extra)
      inscrever(navegador, processo, valores, **extra)
      codigo_recebido(valores["Correio"] || extra[:email])
    end

    it "ignora o nome e o e-mail que a tela de edicao nao oferece" do
      codigo = inscrita(@sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: "pessoa@example.com")
      sessao = navegador

      enviar(sessao, @sem_sessao, codigo, { "Dado" => "dado" }, name: "Trocado", email: "alheio@example.com")

      inscricao = Admissions::AdmissionApplication.find_by!(token: codigo)
      expect([inscricao.name, inscricao.email]).to eq(["Pessoa", "pessoa@example.com"])
      expect(sessao.response.location).to end_with(
        admission_apply_path(admission_id: @sem_sessao.simple_id, id: codigo)
      )
    end

    # A troca pedida pelo candidato, pelo campo do formulário sincronizado com
    # o e-mail, só vale depois de confirmada pelo endereço novo: quem a cobra,
    # do pedido à entrega do código novo, é o application_email_change_spec.rb.
    it "nao troca o e-mail nem o codigo quando o campo do formulario pede outro endereco" do
      antigo = inscrita(@com_campo, { "Dado" => "dado", "Correio" => "pessoa@example.com" }, name: "Pessoa")
      sessao = navegador
      @enviados.clear

      enviar(sessao, @com_campo, antigo, { "Dado" => "dado", "Correio" => "alheio@example.com" })

      inscricao = Admissions::AdmissionApplication.find_by!(token: antigo)
      expect(inscricao.email).to eq("pessoa@example.com")
      expect(codigo_recebido("alheio@example.com")).to be_nil
      expect(abre?(sessao, @com_campo, antigo)).to be(true)
    end

    # Controle: a edição que não muda o e-mail mantém o código e volta para a
    # inscrição.
    it "mantem o codigo quando a edicao nao muda o e-mail" do
      codigo = inscrita(@com_campo, { "Dado" => "dado", "Correio" => "pessoa@example.com" }, name: "Pessoa")
      sessao = navegador

      enviar(sessao, @com_campo, codigo, { "Dado" => "outro dado", "Correio" => "pessoa@example.com" })

      expect(sessao.response.location).to end_with(
        admission_apply_path(admission_id: @com_campo.simple_id, id: codigo)
      )
      expect(Admissions::AdmissionApplication.find_by!(token: codigo).filled_form.fields.first.value).to eq("outro dado")
    end

    # Controle: a edição recusada pelo servidor não troca o código.
    it "mantem o codigo quando a troca de e-mail e recusada" do
      create_application(@com_campo, name: "Ocupante", email: "ocupado@example.com")
      codigo = inscrita(@com_campo, { "Dado" => "dado", "Correio" => "pessoa@example.com" }, name: "Pessoa")
      sessao = navegador
      allow(ExceptionNotifier).to receive(:notify_exception)

      enviar(sessao, @com_campo, codigo, { "Dado" => "dado", "Correio" => "ocupado@example.com" })

      expect(sessao.response).to have_http_status(:ok)
      expect(Admissions::AdmissionApplication.find_by(token: codigo)&.email).to eq("pessoa@example.com")
      expect(abre?(sessao, @com_campo, codigo)).to be(true)
    end
  end

  describe "recuperacao do codigo por e-mail" do
    it "manda o codigo para o endereco gravado na inscricao" do
      inscricao = create_application(@sem_sessao, name: "Pessoa", email: "pessoa@example.com")

      entrar(navegador, @sem_sessao, "pessoa@example.com", "forgot")

      expect(@enviados.map { |mensagem| mensagem[:to] }).to eq(["pessoa@example.com"])
      expect(codigo_recebido("pessoa@example.com")).to eq(inscricao.token)
    end

    # Em MariaDB a busca pelo e-mail ignora caixa e acento. O endereço digitado
    # pode ser de outra caixa; o código segue para o gravado. Em SQLite a busca
    # não casa e nada é enviado, o que também satisfaz o exemplo.
    it "nao manda o codigo para um endereco que so se parece com o gravado" do
      create_application(@sem_sessao, name: "Pessoa", email: "joao@example.com")

      ["joão@example.com", "JOAO@example.com", "joao@exámple.com"].each do |parecido|
        entrar(navegador, @sem_sessao, parecido, "forgot")
      end

      expect(@enviados.map { |mensagem| mensagem[:to] }.uniq - ["joao@example.com"]).to be_empty
    end
  end

  # A mensagem da pré-inscrição vai para um endereço que quem pediu digitou:
  # ela não repete o nome digitado, que seria texto de terceiro numa mensagem
  # do programa.
  it "nao repete na mensagem da pre-inscricao o nome que quem pediu digitou" do
    pedir(navegador, @com_sessao, "Clique em http://exemplo.invalido", "pessoa@example.com")

    mensagem = @enviados.find { |m| m[:to] == "pessoa@example.com" }
    expect(mensagem[:body]).not_to include("exemplo.invalido")
    expect(mensagem[:body]).to include(@com_sessao.title)
  end

  # A tela só afirma o envio que houve. Com o envio desligado (a variável
  # redirect_email vazia, por exemplo), a inscrição existe e a tela manda
  # procurar a secretaria, que vê o código.
  describe "quando o sistema nao esta enviando e-mail" do
    before(:each) { allow(Notifier).to receive(:sending?).and_return(false) }

    it "nao afirma que mandou o codigo da pre-inscricao" do
      sessao = navegador

      pedir(sessao, @com_sessao, "Pessoa", "pessoa@example.com")

      inscricao = Admissions::AdmissionApplication.find_by!(email: "pessoa@example.com")
      pagina = resposta_inteira(sessao)
      expect(pagina).not_to include(inscricao.token)
      expect(pagina).not_to include("Enviamos o código")
      expect(pagina).to include("não está enviando e-mails")
    end

    it "nao afirma que mandou os codigos na recuperacao por e-mail" do
      create_application(@com_sessao, name: "Pessoa", email: "pessoa@example.com")
      sessao = navegador

      entrar(sessao, @com_sessao, "pessoa@example.com", "forgot")

      pagina = resposta_inteira(sessao)
      expect(pagina).not_to include("Email enviado para")
      expect(pagina).to include("não está enviando e-mails")
    end

    it "nao afirma que mandou o codigo da inscricao enviada sem sessao" do
      sessao = navegador

      inscrever(sessao, @sem_sessao, { "Dado" => "dado" }, name: "Pessoa", email: "pessoa@example.com")

      pagina = resposta_inteira(sessao)
      expect(Admissions::AdmissionApplication.exists?(email: "pessoa@example.com")).to be(true)
      expect(pagina).not_to include("foram enviados para")
      expect(pagina).to include("não está enviando e-mails")
    end
  end

  describe "geracao do codigo" do
    it "sorteia cada caractere pelo gerador criptografico" do
      allow(SecureRandom).to receive(:rand).and_call_original

      inscricao = create_application(@com_sessao, name: "Pessoa")

      expect(inscricao.token.sub(formato_do_codigo, "")).to eq("")
      expect(SecureRandom).to have_received(:rand).at_least(18).times
    end
  end
end
