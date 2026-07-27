# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Notificações do fluxo de inscrição em disciplinas.
#
# O processo tem sete passos, e três deles dependem de e-mail por design -- o
# passo 2 chama a mensagem de "uma forma de recibo". São onze templates no
# EmailTemplate, e nenhum tinha spec: nenhum arquivo da suíte conferia
# ActionMailer::Base.deliveries em nenhum ponto deste fluxo.
#
# Estes exemplos não julgam o conteúdo das mensagens; fixam QUEM recebe e QUANTAS
# saem, que é onde os erros silenciosos moram -- um laço por orientação que não
# roda, ou um e-mail por disciplina onde deveria haver um por pedido.
RSpec.describe "Notificações do fluxo de inscrição", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @role_professor = FactoryBot.create(:role_professor)
    @level = FactoryBot.create(:level, name: "Mestrado")
    # user: true e obrigatório -- _valid_enrollment levanta AccessDenied se a
    # situação de matrícula não permitir acesso do próprio aluno.
    @enrollment_status = FactoryBot.create(
      :enrollment_status, name: "Regular", user: true
    )

    @student = FactoryBot.create(
      :student, name: "Ana Conceição", cpf: "fluxo-1", email: "ana.fluxo@ic.uff.br"
    )
    @enrollment = FactoryBot.create(
      :enrollment,
      enrollment_number: "M2020001",
      student: @student,
      level: @level,
      enrollment_status: @enrollment_status,
      admission_date: Date.new(2020, 3, 1)
    )

    @course_type = FactoryBot.create(:course_type, name: "Obrigatória", has_score: true)
    @course = FactoryBot.create(
      :course, name: "Engenharia de Software", code: "TCC00001",
      course_type: @course_type, credits: 4, workload: 60
    )
    @professor = FactoryBot.create(
      :professor, name: "João Pereira", email: "joao.fluxo@ic.uff.br"
    )
    @course_class = FactoryBot.create(
      :course_class, course: @course, professor: @professor, year: 2020, semester: 1
    )

    @admin = create_confirmed_user([@role_adm], "fluxo_admin@ic.uff.br")
  end

  # A montagem envia e-mail por conta própria -- criar uma orientação dispara
  # "Nova orientação" ao professor, e criar usuário confirmado dispara as
  # instruções de confirmação. Limpar aqui, imediatamente antes da ação, é o que
  # separa o que o fluxo envia do ruído do cenário.
  def limpar_caixa
    ActionMailer::Base.deliveries.clear
  end

  # Cria o pedido já no estado que cada cenário precisa, sem passar pela tela do
  # aluno: o objetivo aqui é a notificação, não a montagem do formulário.
  def pedido_com_disciplina(status: ClassEnrollmentRequest::REQUESTED)
    pedido = FactoryBot.create(
      :enrollment_request, enrollment: @enrollment, year: 2020, semester: 1
    )
    FactoryBot.create(
      :class_enrollment_request,
      enrollment_request: pedido, course_class: @course_class, status: status
    )
    pedido.reload
  end

  # ClassSchedule#enroll_open? usa Time.now, então a janela precisa conter o
  # instante congelado -- senão o spec passa ou falha conforme o dia da execução.
  def janela_de_inscricao
    FactoryBot.create(
      :class_schedule, year: 2020, semester: 1,
      enrollment_start: Time.utc(2020, 3, 1), enrollment_end: Time.utc(2020, 3, 31),
      period_start: Time.utc(2020, 3, 1), period_end: Time.utc(2020, 7, 31),
      enrollment_insert: Time.utc(2020, 3, 1), enrollment_remove: Time.utc(2020, 3, 31),
      grades_deadline: Time.utc(2020, 8, 31)
    )
  end

  def com_orientador(quantos: 1)
    quantos.times do |i|
      professor = i.zero? ? @professor : FactoryBot.create(
        :professor, name: "Orientador #{i}", email: "orientador#{i}@ic.uff.br"
      )
      FactoryBot.create(
        :advisement_authorization, professor: professor, level: @level
      )
      FactoryBot.create(
        :advisement, professor: professor, enrollment: @enrollment,
        main_advisor: i.zero?
      )
      # A validação "um dos orientadores deve ser principal" olha a coleção, e o
      # @enrollment em memória não enxerga o que acabou de ser criado.
      @enrollment.reload
    end
  end

  describe "passo 3 — o orientador decide e salva o pedido" do
    before(:each) do
      com_orientador
      @pedido = pedido_com_disciplina
      sign_in @admin
    end

    # O formulário submete, por pedido, quatro campos:
    #   record[class_enrollment_requests][<id>][{id,course_class,class_enrollment,status}]
    # mais uma entrada "0" vazia. Reproduzir o shape inteiro não é capricho: com
    # o nome errado o status não muda e o e-mail sai só pelo comentário, dando um
    # teste verde que não exercita a decisão; e mandando só o status o
    # active_scaffold destrói os pedidos que julgou ausentes.
    it "envia UM e-mail ao aluno ao salvar, não um por disciplina" do
      cer = @pedido.class_enrollment_requests.first
      limpar_caixa

      put enrollment_request_path(@pedido), params: {
        record: {
          comment_message: "Combinamos na reunião de orientação.",
          class_enrollment_requests: {
            "0" => "",
            cer.id.to_s => {
              id: cer.id.to_s,
              course_class: cer.course_class_id.to_s,
              class_enrollment: cer.class_enrollment_id.to_s,
              status: ClassEnrollmentRequest::VALID
            }
          }
        }
      }

      expect(cer.reload.status).to eq(ClassEnrollmentRequest::VALID)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to include(@student.email)
    end

    it "envia UM e-mail mesmo decidindo várias disciplinas de uma vez" do
      outra = FactoryBot.create(
        :course, name: "Banco de Dados", code: "TCC00002",
        course_type: @course_type, credits: 4, workload: 60
      )
      outra_turma = FactoryBot.create(
        :course_class, course: outra, professor: @professor, year: 2020, semester: 1
      )
      segundo = FactoryBot.create(
        :class_enrollment_request, enrollment_request: @pedido,
        course_class: outra_turma, status: ClassEnrollmentRequest::REQUESTED
      )
      primeiro = @pedido.class_enrollment_requests.first
      limpar_caixa

      put enrollment_request_path(@pedido), params: {
        record: {
          comment_message: "A segunda não cabe na sua carga.",
          class_enrollment_requests: {
            "0" => "",
            primeiro.id.to_s => {
              id: primeiro.id.to_s,
              course_class: primeiro.course_class_id.to_s,
              class_enrollment: primeiro.class_enrollment_id.to_s,
              status: ClassEnrollmentRequest::VALID
            },
            segundo.id.to_s => {
              id: segundo.id.to_s,
              course_class: segundo.course_class_id.to_s,
              class_enrollment: segundo.class_enrollment_id.to_s,
              status: ClassEnrollmentRequest::INVALID
            }
          }
        }
      }

      expect(primeiro.reload.status).to eq(ClassEnrollmentRequest::VALID)
      expect(segundo.reload.status).to eq(ClassEnrollmentRequest::INVALID)
      # Uma decisão completa por aluno, um e-mail -- não um por disciplina.
      expect(ActionMailer::Base.deliveries.size).to eq(1)
    end

    it "não envia nada quando nada muda" do
      limpar_caixa

      put enrollment_request_path(@pedido), params: {
        record: { comment_message: "" }
      }

      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  # O caminho secundário: os botões "Válido"/"Inválido" na lista de disciplinas.
  # O ability.rb faz `alias_action :set_invalid, :set_requested, :set_valid, to:
  # :update`, então o orientador enxerga esses botões para seus orientandos.
  #
  # Eles mudam o status SEM notificar -- set_status só envia quando recebe bloco,
  # e só set_effected passa um. Este exemplo fixa o comportamento atual para que a
  # diferença entre os dois caminhos deixe de ser tácita. Se for defeito, ele vira
  # a especificação do conserto; se for deliberado, vira documentação.
  describe "passo 3 — o orientador usa os botões da lista" do
    before(:each) do
      com_orientador
      @pedido = pedido_com_disciplina
      sign_in @admin
    end

    it "muda o status sem notificar o aluno" do
      cer = @pedido.class_enrollment_requests.first
      limpar_caixa

      put set_invalid_class_enrollment_request_path(cer)

      expect(cer.reload.status).to eq(ClassEnrollmentRequest::INVALID)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  # Passos 2 e 4 -- a tela do aluno. O enroll_open? do ClassSchedule usa Time.now,
  # então o relógio congela dentro da janela de inscrição; sem isso o spec
  # passaria ou falharia conforme o dia em que a suíte rodasse.
  describe "passo 2 — o aluno faz o pedido" do
    before(:each) do
      @role_aluno = FactoryBot.create(:role_aluno)
      @aluno = create_confirmed_user(
        [@role_aluno], @student.email, "Ana Conceição", "A1b2c3d4!",
        student: @student
      )
      @periodo = janela_de_inscricao
      travel_to Time.utc(2020, 3, 15, 12, 0, 0)
    end

    after(:each) { travel_back }

    it "notifica o aluno e CADA orientador" do
      com_orientador(quantos: 2)
      sign_in @aluno
      limpar_caixa

      post save_student_enroll_path(id: @enrollment.id, year: 2020, semester: 1),
        params: { enrollment_request: {
          course_class_ids: [@course_class.id.to_s],
          message: "Acertei com meu orientador."
        } }

      destinatarios = ActionMailer::Base.deliveries.flat_map(&:to)
      # Um ao aluno e um por orientação: o laço sobre advisements é onde um aluno
      # com dois orientadores deixa de notificar um deles em silêncio.
      expect(destinatarios).to include(@student.email)
      expect(destinatarios.size).to eq(3)
      expect(EnrollmentRequest.where(enrollment: @enrollment).count).to eq(1)
    end

    # A chave `message` decide o ramo que monta o comentário e dispara os
    # e-mails, e é lá que a ausência dela doía: `message.empty?` num nil. Pela
    # tela não acontece -- o textarea sempre é submetido, ainda que vazio -- mas
    # o método não deve depender disso para não estourar.
    it "salva sem a chave message, em vez de estourar" do
      com_orientador
      sign_in @aluno
      limpar_caixa

      post save_student_enroll_path(id: @enrollment.id, year: 2020, semester: 1),
        params: { enrollment_request: {
          course_class_ids: [@course_class.id.to_s]
        } }

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(flash[:notice]).to eq(
        I18n.t("student_enrollment.notice.request_saved")
      )
      expect(EnrollmentRequest.where(enrollment: @enrollment).count).to eq(1)
      # Sem mensagem não há comentário, mas a notificação continua saindo.
      expect(EnrollmentRequestComment.count).to eq(0)
      expect(ActionMailer::Base.deliveries.flat_map(&:to))
        .to include(@student.email)
    end
  end

  describe "passo 4 — o aluno desfaz o pedido" do
    before(:each) do
      @role_aluno ||= FactoryBot.create(:role_aluno)
      @aluno = create_confirmed_user(
        [@role_aluno], @student.email, "Ana Conceição", "A1b2c3d4!",
        student: @student
      )
      @periodo = janela_de_inscricao
      travel_to Time.utc(2020, 3, 15, 12, 0, 0)
      com_orientador
      @pedido = pedido_com_disciplina(status: ClassEnrollmentRequest::INVALID)
      sign_in @aluno
    end

    after(:each) { travel_back }

    it "notifica o aluno e cada orientador ao apagar o pedido inteiro" do
      limpar_caixa

      post save_student_enroll_path(id: @enrollment.id, year: 2020, semester: 1),
        params: { enrollment_request: { delete_request: "1" } }

      destinatarios = ActionMailer::Base.deliveries.flat_map(&:to)
      expect(destinatarios).to include(@student.email)
      expect(destinatarios).to include(@professor.email)
      expect(EnrollmentRequest.where(enrollment: @enrollment).count).to eq(0)
    end

    it "envia UM e-mail ao trocar a disciplina invalidada por outra" do
      outra = FactoryBot.create(
        :course, name: "Banco de Dados", code: "TCC00002",
        course_type: @course_type, credits: 4, workload: 60
      )
      outra_turma = FactoryBot.create(
        :course_class, course: outra, professor: @professor, year: 2020, semester: 1
      )
      limpar_caixa

      # O passo 4 do processo: tira a que o orientador invalidou e põe outra.
      post save_student_enroll_path(id: @enrollment.id, year: 2020, semester: 1),
        params: { enrollment_request: {
          course_class_ids: [outra_turma.id.to_s],
          message: "Troquei conforme sua orientação."
        } }

      turmas = @pedido.reload.class_enrollment_requests.map(&:course_class_id)
      expect(turmas).to eq([outra_turma.id])
      # Uma submissão do aluno, um e-mail para ele -- mais um por orientação.
      expect(ActionMailer::Base.deliveries.map(&:to).flatten)
        .to include(@student.email)
    end
  end

  describe "passo 5 — a secretaria efetiva" do
    before(:each) do
      @pedido = pedido_com_disciplina(status: ClassEnrollmentRequest::VALID)
      sign_in @admin
    end

    it "notifica o aluno ao efetivar uma disciplina" do
      cer = @pedido.class_enrollment_requests.first
      limpar_caixa

      put set_effected_class_enrollment_request_path(cer)

      expect(cer.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(ActionMailer::Base.deliveries.size).to eq(1)
      expect(ActionMailer::Base.deliveries.first.to).to include(@student.email)
    end
  end
end
