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
end
