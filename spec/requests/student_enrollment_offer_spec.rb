# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O pedido de inscrição só aceita o que a tela ofereceu ao aluno: as turmas da
# grade do semestre e, na disciplina sob demanda listada, um dos professores do
# seletor. A disciplina sob demanda cria a turma ao ser pedida, então aceitar
# professor ou disciplina de fora da oferta grava turma que ninguém abriu.
RSpec.describe "StudentEnrollmentController offer check", type: :request do
  before(:each) do
    role = FactoryBot.create(:role_aluno)
    @level = FactoryBot.create(:level, name: "Mestrado")
    status = FactoryBot.create(:enrollment_status, name: "Regular", user: true)
    student = FactoryBot.create(:student, name: "Ana")
    @enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M01", student: student,
      level: @level, enrollment_status: status
    )
    user = create_confirmed_user(
      [role], "ana.sapos@ic.uff.br", "Ana", "A1b2c3d4!", student: student
    )
    sign_in user
    FactoryBot.create(
      :class_schedule, year: 2026, semester: 2,
      enrollment_start: 3.days.ago, enrollment_end: 3.days.from_now
    )
    @on_demand_type = FactoryBot.create(:course_type, on_demand: true)
    @course = FactoryBot.create(:course, course_type: @on_demand_type)
    @accredited = FactoryBot.create(:professor, name: "Credenciado")
    FactoryBot.create(
      :advisement_authorization, professor: @accredited, level: @level,
      start_date: Date.current - 1.day, end_date: nil
    )
    @outsider = FactoryBot.create(:professor, name: "ForaDaLista")
  end

  def submit(course_class_ids: [], course_ids: {})
    post "/enrollment/#{@enrollment.id}/enroll/2026-2", params: {
      enrollment_request: {
        course_class_ids: [""] + course_class_ids.map(&:to_s), message: "",
        course_ids: course_ids.to_h do |course, professor|
          [course.id.to_s, { selected: "1", professor: professor.id.to_s }]
        end
      }
    }
  end

  def classes_of(course, professor)
    CourseClass.where(
      course: course, professor: professor, year: 2026, semester: 2
    )
  end

  def rejected!
    expect(response).to have_http_status(:ok)
    expect(flash[:alert]).to eq(
      I18n.t("student_enrollment.enroll.errors.not_offered")
    )
    expect(ClassEnrollmentRequest.count).to eq(0)
  end

  describe "on-demand course" do
    it "creates the class for a professor of the selector" do
      submit(course_ids: { @course => @accredited })

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(classes_of(@course, @accredited).count).to eq(1)
      expect(ClassEnrollmentRequest.count).to eq(1)
    end

    it "accepts the professor of a class already open in the semester" do
      FactoryBot.create(
        :course_class, course: @course, professor: @outsider,
        year: 2026, semester: 2
      )

      submit(course_ids: { @course => @outsider })

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(classes_of(@course, @outsider).count).to eq(1)
      expect(ClassEnrollmentRequest.count).to eq(1)
    end

    it "rejects a professor outside the selector without creating a class" do
      submit(course_ids: { @course => @outsider })

      rejected!
      expect(classes_of(@course, @outsider)).to be_empty
    end

    it "rejects an unavailable course that has no class in the semester" do
      @course.update!(available: false)

      submit(course_ids: { @course => @accredited })

      rejected!
      expect(classes_of(@course, @accredited)).to be_empty
    end

    # A gravação recusada pelo modelo (aqui, choque de horário) acontece
    # depois de criada a turma sob demanda, e a página volta com ela marcada
    # entre as turmas. Reenviar a página, sem o choque, tem de valer.
    it "accepts on resubmit the class created by a save the model refused" do
      regular_type = FactoryBot.create(:course_type, on_demand: false)
      first, second = 2.times.map do
        course_class = FactoryBot.create(
          :course_class,
          course: FactoryBot.create(:course, course_type: regular_type),
          professor: @outsider, year: 2026, semester: 2
        )
        FactoryBot.create(:allocation, course_class: course_class)
        course_class
      end

      submit(
        course_class_ids: [first.id, second.id],
        course_ids: { @course => @accredited }
      )
      expect(response).to have_http_status(:ok)
      expect(ClassEnrollmentRequest.count).to eq(0)
      created = classes_of(@course, @accredited).sole

      post "/enrollment/#{@enrollment.id}/enroll/2026-2", params: {
        enrollment_request: {
          course_class_ids: ["", first.id.to_s, created.id.to_s], message: "",
          course_ids: {
            @course.id.to_s => { selected: "0", professor: @accredited.id.to_s }
          }
        }
      }

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(ClassEnrollmentRequest.where(course_class: created).count).to eq(1)
    end

    it "rejects a class of the course from another semester" do
      course_class = FactoryBot.create(
        :course_class, course: @course, professor: @accredited,
        year: 2020, semester: 1
      )

      submit(course_class_ids: [course_class.id])

      rejected!
    end

    # A recusa redesenha a própria página, e a mensagem pede para recarregá-la:
    # a página recarregada não pode repetir o alerta.
    it "shows the refusal alert only on the page that refused" do
      submit(course_ids: { @course => @outsider })
      rejected!
      alerta = I18n.t("student_enrollment.enroll.errors.not_offered")
      expect(response.body).to include(alerta)

      get "/enrollment/#{@enrollment.id}/enroll/2026-2"

      expect(response).to have_http_status(:ok)
      expect(flash[:alert]).to be_nil
      expect(response.body).not_to include(alerta)
    end

    it "rejects a course that is not on demand without creating a class" do
      regular = FactoryBot.create(
        :course, course_type: FactoryBot.create(:course_type, on_demand: false)
      )

      submit(course_ids: { regular => @accredited })

      rejected!
      expect(classes_of(regular, @accredited)).to be_empty
    end
  end

  describe "regular class" do
    before(:each) do
      regular_type = FactoryBot.create(:course_type, on_demand: false)
      @regular = FactoryBot.create(:course, course_type: regular_type)
    end

    it "accepts a class of the semester grid" do
      course_class = FactoryBot.create(
        :course_class, course: @regular, professor: @accredited,
        year: 2026, semester: 2
      )

      submit(course_class_ids: [course_class.id])

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(ClassEnrollmentRequest.where(course_class: course_class).count)
        .to eq(1)
    end

    it "rejects a class of another semester" do
      course_class = FactoryBot.create(
        :course_class, course: @regular, professor: @accredited,
        year: 2020, semester: 1
      )

      submit(course_class_ids: [course_class.id])

      rejected!
    end

    it "keeps a class already in the request even if the grid no longer lists it" do
      course_class = FactoryBot.create(
        :course_class, course: @regular, professor: @accredited,
        year: 2026, semester: 2
      )
      submit(course_class_ids: [course_class.id])
      expect(ClassEnrollmentRequest.count).to eq(1)
      course_class.update!(not_schedulable: true)

      submit(course_class_ids: [course_class.id])

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(flash[:alert]).to be_nil
      expect(ClassEnrollmentRequest.count).to eq(1)
    end
  end
end
