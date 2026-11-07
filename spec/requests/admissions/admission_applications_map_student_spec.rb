# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Cobre a única transação de banco explícita da aplicação:
# Admissions::AdmissionApplicationsController#do_map_student_form_create_update.
#
# Esta ação envolve a criação/atualização de um Student e de um Enrollment em um
# ActiveRecord::Base.transaction e faz rollback (raise ActiveRecord::Rollback)
# quando algum dos registros é inválido. O objetivo destes testes é provar a
# ATOMICIDADE: ou os dois persistem, ou nenhum persiste.
RSpec.describe "Admissions::AdmissionApplications map_student transaction",
  type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "map_student_admin@ic.uff.br")
    sign_in @admin

    # Cenário mínimo de admissão: uma inscrição sem aluno e sem matrícula
    # associados (mapping "new" para ambos).
    @admission_application = FactoryBot.create(:admission_application)

    # Dados necessários para criar uma matrícula válida.
    @level = FactoryBot.create(:level)
    @enrollment_status = FactoryBot.create(:enrollment_status)

    # A renderização (respond_to_action) reconstrói o formulário completo do
    # ActiveScaffold para Student e Enrollment, o que é irrelevante para o que
    # estamos testando (a transação, que ocorre inteiramente em
    # do_map_student_form_create_update, antes da resposta). Substituímos apenas
    # a resposta por um head :ok para manter o teste robusto entre bancos e
    # versões do Rails, sem tocar em nenhuma lógica da transação.
    allow_any_instance_of(Admissions::AdmissionApplicationsController)
      .to receive(:respond_to_action) { |controller, *| controller.head :ok }
  end

  def valid_student_params
    { name: "Novo Aluno", cpf: "map-student-cpf-1" }
  end

  def valid_enrollment_params
    {
      enrollment_number: "M-map-student-1",
      "admission_date(1i)" => "2024",
      "admission_date(2i)" => "1",
      "admission_date(3i)" => "1",
      enrollment_status: @enrollment_status.id,
      level: @level.id,
    }
  end

  def do_map_student(record_student:, record_enrollment:)
    post map_student_form_create_update_admission_application_path(
      @admission_application
    ), params: {
      record_student: record_student,
      record_enrollment: record_enrollment,
    }
  end

  describe "POST map_student_form_create_update" do
    it "creates both a Student and an Enrollment atomically on success" do
      expect do
        do_map_student(
          record_student: valid_student_params,
          record_enrollment: valid_enrollment_params
        )
      end.to change { Student.count }.by(1)
        .and change { Enrollment.count }.by(1)

      student = Student.order(:id).last
      enrollment = Enrollment.order(:id).last
      expect(student.name).to eq("Novo Aluno")
      expect(student.cpf).to eq("map-student-cpf-1")
      expect(enrollment.enrollment_number).to eq("M-map-student-1")
      expect(enrollment.student).to eq(student)

      # A inscrição passa a apontar para o aluno e a matrícula recém-criados.
      @admission_application.reload
      expect(@admission_application.student).to eq(student)
      expect(@admission_application.enrollment).to eq(enrollment)
    end

    it "rolls back and persists NEITHER record when the enrollment is invalid" do
      # O aluno é individualmente válido; a matrícula é inválida
      # (enrollment_number em branco viola a validação de presença). A
      # atomicidade exige que o aluno válido TAMBÉM não seja persistido.
      invalid_enrollment = valid_enrollment_params.merge(enrollment_number: "")

      expect do
        do_map_student(
          record_student: valid_student_params,
          record_enrollment: invalid_enrollment
        )
      end.to change { Student.count }.by(0)
        .and change { Enrollment.count }.by(0)

      # A inscrição continua sem aluno e sem matrícula.
      @admission_application.reload
      expect(@admission_application.student).to be_nil
      expect(@admission_application.enrollment).to be_nil
    end

    it "rolls back and persists NEITHER record when the student is invalid" do
      # Caminho simétrico: aluno inválido (cpf em branco viola presença),
      # matrícula individualmente válida. Nada deve persistir.
      invalid_student = valid_student_params.merge(cpf: "")

      expect do
        do_map_student(
          record_student: invalid_student,
          record_enrollment: valid_enrollment_params
        )
      end.to change { Student.count }.by(0)
        .and change { Enrollment.count }.by(0)

      @admission_application.reload
      expect(@admission_application.student).to be_nil
      expect(@admission_application.enrollment).to be_nil
    end
  end

  # A criacao esta coberta acima. Os caminhos abaixo -- aluno e matricula ja
  # ligados, aluno existente vinculado por id e o resgate de registro nao
  # salvo -- passam pelos send(:before_update_save) dos controllers do
  # active_scaffold e pelos rescues, que nenhum exemplo percorria (#720).
  describe "POST map_student_form_create_update sobre registros existentes" do
    before(:each) do
      @aluno = Student.create!(name: "Aluno Antigo", cpf: "map-student-cpf-2")
      @matricula = Enrollment.create!(
        student: @aluno, enrollment_number: "M-antiga", level: @level,
        enrollment_status: @enrollment_status, admission_date: Date.new(2024, 1, 1)
      )
    end

    it "atualiza o aluno e a matricula ja ligados, sem criar outros" do
      @admission_application.update!(student: @aluno, enrollment: @matricula)

      expect do
        do_map_student(
          record_student: { name: "Aluno Renomeado", cpf: "map-student-cpf-2" },
          record_enrollment: valid_enrollment_params.merge(enrollment_number: "M-nova")
        )
      end.to change { Student.count }.by(0).and change { Enrollment.count }.by(0)

      expect(@aluno.reload.name).to eq("Aluno Renomeado")
      expect(@matricula.reload.enrollment_number).to eq("M-nova")
    end

    it "vincula o aluno existente indicado e cria so a matricula" do
      expect do
        post map_student_form_create_update_admission_application_path(@admission_application),
          params: {
            student_id: @aluno.id,
            record_student: { name: "Aluno Antigo", cpf: "map-student-cpf-2" },
            record_enrollment: valid_enrollment_params
          }
      end.to change { Student.count }.by(0).and change { Enrollment.count }.by(1)

      @admission_application.reload
      expect(@admission_application.student).to eq(@aluno)
      expect(@admission_application.enrollment.student).to eq(@aluno)
    end

    it "nao persiste nada quando a gravacao de um associado falha" do
      allow_any_instance_of(Student).to receive(:save_associated!)
        .and_raise(ActiveRecord::RecordNotSaved.new("falhou"))

      expect do
        do_map_student(
          record_student: valid_student_params,
          record_enrollment: valid_enrollment_params
        )
      end.to change { Student.count }.by(0).and change { Enrollment.count }.by(0)

      expect(@admission_application.reload.student).to be_nil
    end
  end

  # Depois de self.successful = true, as linhas "self.successful = successful? ||
  # [valid?, associated_valid?].all?" curto-circuitam: a validacao do aluno e da
  # matricula nunca roda ali. O invalido so e barrado pelo save!, cujo
  # RecordInvalid cai no rescue generico, que poe a mensagem crua da excecao no
  # flash, alem do erro no campo.
  describe "POST map_student_form_create_update com aluno invalido" do
    before(:each) do
      do_map_student(
        record_student: valid_student_params.merge(cpf: "", name: "Nome Digitado"),
        record_enrollment: valid_enrollment_params
      )
      # A resposta esta trocada por head :ok neste arquivo; o que o formulario
      # mostraria e o @student que o controller deixa para a view.
      @aluno = controller.instance_variable_get(:@student)
    end

    # Controle: nada e gravado, e o formulario volta com o digitado e o erro no
    # campo, antes e depois do conserto.
    it "nao grava e devolve o aluno com o erro no campo" do
      expect(@admission_application.reload.student).to be_nil
      expect(@aluno.name).to eq("Nome Digitado")
      expect(@aluno.errors[:cpf]).to be_present
    end

    it "nao repete o erro como mensagem crua de excecao", pending: "issue #731" do
      expect(flash[:error]).to be_nil
    end
  end
end
