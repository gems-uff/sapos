# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A secretaria grava um pedido de inscrição que uma das disciplinas não deixa
# gravar. O formulário e o lote têm de dizer o que recusaram e por quê.
#
# O formulário revalida toda disciplina enviada, mesmo a que não mudou
# (active_scaffold, associated_valid?), e o erro fica na disciplina, não no
# pedido. A recusa tem de mostrar o erro e manter a escolha enviada. O lote
# efetiva o que pode e tem de listar o que não efetivou.
#
# Cenário: o aluno pediu X (disciplina C) e Y (disciplina D) quando ainda não
# tinha nota em C; depois a nota de C foi revista para aprovado, e X deixa de
# poder ser efetivada (previously_approved). A entrega do e-mail é conferida
# no ActionMailer::Base.deliveries, sem stub do Notifier.
RSpec.describe "Pedido de inscrição: recusa com mensagem", type: :request do
  requested = ClassEnrollmentRequest::REQUESTED
  invalid = ClassEnrollmentRequest::INVALID
  effected = ClassEnrollmentRequest::EFFECTED

  before(:each) do
    level = FactoryBot.create(:level)
    student = FactoryBot.create(:student, email: "aluno.recusa@example.com")
    @enrollment = FactoryBot.create(
      :enrollment, student: student, level: level,
      enrollment_status: FactoryBot.create(:enrollment_status, user: true)
    )
    FactoryBot.create(
      :class_schedule, year: 2026, semester: 2,
      enrollment_start: 30.days.ago, enrollment_end: 20.days.ago,
      period_start: 10.days.ago, enrollment_insert: 3.days.from_now,
      enrollment_remove: 3.days.from_now
    )
    @type = FactoryBot.create(:course_type, on_demand: false, allow_multiple_classes: false)
    @course_c = FactoryBot.create(:course, name: "Calculo", course_type: @type)
    course_d = FactoryBot.create(:course, name: "Dados", course_type: @type)
    @professor = FactoryBot.create(:professor)
    @x = FactoryBot.create(:course_class, course: @course_c, professor: @professor, year: 2026, semester: 2)
    @y = FactoryBot.create(:course_class, course: course_d, professor: @professor, year: 2026, semester: 2)
    @pedido = FactoryBot.create(:enrollment_request, enrollment: @enrollment, year: 2026, semester: 2)
    @anterior = ClassEnrollment.create!(
      enrollment: @enrollment, situation: ClassEnrollment::DISAPPROVED,
      course_class: FactoryBot.create(
        :course_class, course: @course_c, professor: @professor, year: 2026, semester: 1
      )
    )
    @cx = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: @x,
      action: ClassEnrollmentRequest::INSERT, status: requested
    )
    @cy = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: @y,
      action: ClassEnrollmentRequest::INSERT, status: requested
    )
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.recusa@ic.uff.br", "Adm")
    # A confirmação do usuário criado acima não é deste assunto.
    ActionMailer::Base.deliveries.clear
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  # Nota revista depois do pedido, por fora das validações, como a revisão
  # numa turma já encerrada.
  def aprova_c_depois
    @anterior.update_columns(situation: ClassEnrollment::APPROVED)
  end

  # Os campos que a tabela de rádios envia, com a inscrição da linha.
  def grava(statuses)
    rows = { "0" => "" }
    statuses.each do |cer, status|
      rows[cer.id.to_s] = {
        id: cer.id.to_s, course_class: cer.course_class_id.to_s,
        class_enrollment: cer.reload.class_enrollment_id.to_s, status: status
      }
    end
    put enrollment_request_path(@pedido), params: {
      record: { comment_message: "", class_enrollment_requests: rows }
    }
  end

  def pagina
    Nokogiri::HTML(response.body)
  end

  # Envia o formulário que a página mostra, como o navegador: cada campo com
  # o valor que veio nela, inclusive os ocultos, e só o status das linhas de
  # `mudancas` trocado. É assim que a secretaria regrava a página que voltou
  # de uma recusa; o `grava` acima lê a inscrição da linha no banco, como a
  # página aberta de novo.
  def envia_pagina(mudancas = {})
    form = pagina.at_css("form[id^='as_enrollment_requests-update']")
    campos = form.css(
      "input[type='hidden']:not([name^='_']), input[type='radio'][checked], textarea"
    ).map { |campo| [campo["name"], campo.name == "textarea" ? campo.text : campo["value"]] }
    mudancas.each do |cer, status|
      nome = "record[class_enrollment_requests][#{cer.id}][status]"
      campos.reject! { |par| par.first == nome }
      campos << [nome, status]
    end
    patch form["action"], params: Rack::Utils.parse_nested_query(URI.encode_www_form(campos))
  end

  def inscrito?(class_enrollment)
    ClassEnrollment.where(id: class_enrollment.id).exists?
  end

  def erros_visiveis
    pagina.css(".errorExplanation li, .association-record-errors li").map { |li| li.text.squish }
  end

  def marcado(cer)
    pagina.at_css(
      "input[type='radio'][name='record[class_enrollment_requests][#{cer.id}][status]'][checked]"
    )&.[]("value")
  end

  def destinatarios
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  def mensagem(atributo, chave)
    ClassEnrollmentRequest.new.errors.full_message(
      atributo,
      I18n.t("activerecord.errors.models.class_enrollment_request.attributes.#{atributo}.#{chave}")
    )
  end

  describe "formulário" do
    it "controle: sem a aprovação posterior, efetiva Y e avisa o aluno" do
      grava(@cx => requested, @cy => effected)

      expect(response).to have_http_status(:redirect)
      expect(@cy.reload.status).to eq(effected)
      expect(destinatarios).to eq(["aluno.recusa@example.com"])
    end

    it "recusa efetivar Y dizendo o que impede X e mantém a escolha" do
      aprova_c_depois

      grava(@cx => requested, @cy => effected)

      expect([@cx.reload.status, @cy.reload.status]).to eq([requested, requested])
      expect(destinatarios).to eq([])
      expect(erros_visiveis).to include(
        I18n.t("activerecord.errors.models.enrollment_request.attributes.base.invalid_class.one"),
        mensagem(:course_class, :previously_approved)
      )
      expect(marcado(@cy)).to eq(effected)
    end

    it "nega a disciplina que não pode mais ser efetivada" do
      aprova_c_depois

      grava(@cx => invalid, @cy => requested)

      expect(response).to have_http_status(:redirect)
      expect(@cx.reload.status).to eq(invalid)
      expect(destinatarios).to eq(["aluno.recusa@example.com"])
    end
  end

  # A remoção leva num campo oculto a inscrição que retira. A gravação
  # recusada apaga a inscrição e solta a linha antes de desfazer tudo no
  # banco; a página que volta é montada com a linha em memória. Se o campo
  # oculto vier dela, vem vazio, e a remoção regravada fica Efetivada sem
  # apagar inscrição nenhuma: o aluno continua na turma.
  # O aviso de "pedido já efetivado" (effected-change-alert) acende quando a
  # secretaria tira de Efetivada uma linha que estava efetivada antes da
  # alteração. A página devolvida pela recusa traz a escolha enviada, e o
  # aviso tem de seguir o que está gravado, não a escolha.
  describe "formulário devolvido, aviso de pedido já efetivado" do
    before(:each) do
      expect(@cy.set_status!(effected)).to be(true)
      aprova_c_depois
      ActionMailer::Base.deliveries.clear
    end

    def avisa?(cer)
      pagina.css(
        "input[name='record[class_enrollment_requests][#{cer.id}][status]']"
      ).all? { |radio| radio["class"].split.include?("effected-item") }
    end

    it "controle: a página recém-aberta marca só a linha efetivada" do
      get edit_enrollment_request_path(@pedido)

      expect([avisa?(@cy), avisa?(@cx)]).to eq([true, false])
    end

    it "na página devolvida, marca a linha efetivada no banco, não a escolha enviada" do
      grava(@cx => effected, @cy => requested)
      expect(erros_visiveis).to include(mensagem(:course_class, :previously_approved))
      expect([marcado(@cx), marcado(@cy)]).to eq([effected, requested])

      expect([avisa?(@cy), avisa?(@cx)]).to eq([true, false])
    end
  end

  describe "formulário regravado como voltou da recusa" do
    before(:each) do
      a = FactoryBot.create(
        :course_class, professor: @professor, year: 2026, semester: 2,
        course: FactoryBot.create(:course, name: "Estatistica", course_type: @type)
      )
      @inscricao = ClassEnrollment.create!(
        enrollment: @enrollment, course_class: a, situation: ClassEnrollment::REGISTERED
      )
      @remocao = FactoryBot.create(
        :class_enrollment_request, enrollment_request: @pedido, course_class: a,
        class_enrollment: @inscricao, action: ClassEnrollmentRequest::REMOVE, status: requested
      )
      ActionMailer::Base.deliveries.clear
    end

    it "controle: a página recém-aberta efetiva a remoção e apaga a inscrição" do
      get edit_enrollment_request_path(@pedido)
      envia_pagina(@remocao => effected)

      expect(response).to have_http_status(:redirect)
      expect(@remocao.reload.status).to eq(effected)
      expect(inscrito?(@inscricao)).to be(false)
    end

    it "a página devolvida, com a disciplina bloqueada negada, efetiva a remoção e apaga a inscrição" do
      aprova_c_depois
      get edit_enrollment_request_path(@pedido)
      envia_pagina(@remocao => effected)
      expect(erros_visiveis).to include(mensagem(:course_class, :previously_approved))
      expect(inscrito?(@inscricao)).to be(true)

      envia_pagina(@cx => invalid)

      expect(response).to have_http_status(:redirect)
      expect([@cx.reload.status, @remocao.reload.status]).to eq([invalid, effected])
      expect(inscrito?(@inscricao)).to be(false)
    end
  end

  describe "lote" do
    def efetiva_lista
      get class_enrollment_requests_path
      post effect_class_enrollment_requests_path
    end

    it "controle: sem a aprovação posterior, efetiva as duas sem erro" do
      efetiva_lista

      expect([@cx.reload.status, @cy.reload.status]).to eq([effected, effected])
      expect(flash[:info]).to eq(I18n.t("class_enrollment_request.effected.applied", count: 2))
      expect(flash[:error]).to be_blank
    end

    it "efetiva Y e diz que X não foi efetivada, e por quê" do
      aprova_c_depois

      efetiva_lista

      expect([@cx.reload.status, @cy.reload.status]).to eq([requested, effected])
      expect(flash[:info]).to eq(I18n.t("class_enrollment_request.effected.applied", count: 1))
      expect(Array(flash[:error]).join("\n")).to include(
        @x.to_label, mensagem(:course_class, :previously_approved)
      )
      expect(destinatarios).to include("aluno.recusa@example.com")
    end
  end

  # Troca de turma na mesma disciplina (#781): remoção de A e adição de B,
  # as duas Solicitadas, a adição mais antiga. Negar só a remoção deixa a
  # adição em conflito com a inscrição em A, e a adição, que não mudou, é
  # revalidada. Efetivar as duas numa gravação é recusado com o pedido de
  # gravar a remoção primeiro, e a página devolvida tem de aceitar esse passo.
  describe "formulário, troca de turma" do
    before(:each) do
      @anterior.destroy!
      a = FactoryBot.create(:course_class, course: @course_c, professor: @professor, year: 2026, semester: 2)
      @inscricao = ClassEnrollment.create!(
        enrollment: @enrollment, course_class: a, situation: ClassEnrollment::REGISTERED
      )
      @remocao = FactoryBot.create(
        :class_enrollment_request, enrollment_request: @pedido, course_class: a,
        class_enrollment: @inscricao, action: ClassEnrollmentRequest::REMOVE, status: requested
      )
      @cx.update!(course_class: FactoryBot.create(
        :course_class, course: @course_c, professor: @professor, year: 2026, semester: 2
      ))
      ActionMailer::Base.deliveries.clear
    end

    it "recusa dizendo o que impede a adição e mantém a escolha" do
      grava(@remocao => invalid, @cx => requested, @cy => requested)

      expect(@remocao.reload.status).to eq(requested)
      expect(destinatarios).to eq([])
      expect(erros_visiveis).to include(mensagem(:course_class, :already_enrolled))
      expect(marcado(@remocao)).to eq(invalid)
    end

    it "a página devolvida pela troca numa gravação aceita gravar a remoção primeiro" do
      get edit_enrollment_request_path(@pedido)
      envia_pagina(@remocao => effected, @cx => effected)
      expect(erros_visiveis).to include(
        I18n.t("activerecord.errors.models.enrollment_request.attributes.base.release_first")
      )

      envia_pagina(@cx => requested)

      expect(response).to have_http_status(:redirect)
      expect([@remocao.reload.status, @cx.reload.status]).to eq([effected, requested])
      expect(inscrito?(@inscricao)).to be(false)
    end
  end

  # Troca na disciplina C com a nota da turma anterior revista para aprovado:
  # a adição da troca não passa por previously_approved, que gravar a remoção
  # primeiro não resolve. O aviso de ordem (release_first) só cabe quando o
  # que barra a adição é a inscrição que a remoção libera.
  describe "formulário, troca de turma barrada por outro motivo" do
    before(:each) do
      a = FactoryBot.create(:course_class, course: @course_c, professor: @professor, year: 2026, semester: 2)
      @inscricao = ClassEnrollment.create!(
        enrollment: @enrollment, course_class: a, situation: ClassEnrollment::REGISTERED
      )
      @remocao = FactoryBot.create(
        :class_enrollment_request, enrollment_request: @pedido, course_class: a,
        class_enrollment: @inscricao, action: ClassEnrollmentRequest::REMOVE, status: requested
      )
      ActionMailer::Base.deliveries.clear
    end

    let(:release_first) do
      I18n.t("activerecord.errors.models.enrollment_request.attributes.base.release_first")
    end

    it "controle: sem a aprovação posterior, pede para gravar a remoção primeiro" do
      grava(@remocao => effected, @cx => effected, @cy => requested)

      expect(erros_visiveis).to include(release_first)
      expect(erros_visiveis).to include(mensagem(:course_class, :already_enrolled))
    end

    it "com a aprovação posterior, diz o que impede a adição e não pede a ordem" do
      aprova_c_depois

      grava(@remocao => effected, @cx => effected, @cy => requested)

      expect(erros_visiveis).to include(mensagem(:course_class, :previously_approved))
      expect(erros_visiveis).not_to include(release_first)
      expect([@remocao.reload.status, @cx.reload.status]).to eq([requested, requested])
    end
  end

  # A adição Inválida não confere conflito com a inscrição. Desfazer a adição
  # efetivada apaga a inscrição dela, e o after_destroy da inscrição
  # (ClassEnrollment#set_request_status_after_destroy, da exclusão pela tela
  # de inscrições) marcaria a adição Inválida por cima do status escolhido.
  describe "adição efetivada desfeita" do
    before(:each) do
      put set_effected_class_enrollment_request_path(@cy)
      expect(@cy.reload.status).to eq(effected)
      ActionMailer::Base.deliveries.clear
    end

    it "pelo ícone, volta a Solicitada e apaga a inscrição" do
      put set_requested_class_enrollment_request_path(@cy)

      expect(@cy.reload.status).to eq(requested)
      expect(@cy.class_enrollment).to be_nil
      expect(ClassEnrollment.where(enrollment: @enrollment, course_class: @y)).to be_empty
    end

    it "pelo formulário, volta a Solicitada e apaga a inscrição" do
      grava(@cx => requested, @cy => requested)

      expect(response).to have_http_status(:redirect)
      expect(@cy.reload.status).to eq(requested)
      expect(ClassEnrollment.where(enrollment: @enrollment, course_class: @y)).to be_empty
    end
  end
end
