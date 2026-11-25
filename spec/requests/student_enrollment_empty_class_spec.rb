# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A turma de disciplina sob demanda nasce da gravação do aluno (#347). A turma
# que essa gravação ia usar e deixou sem pedido e sem inscrição fica para trás,
# vazia (#375): a que o pedido recusado criou e a que a troca de professor ou a
# desmarcação esvaziou. As reproduções ficam pending até o conserto; os
# controles fixam o que ele não pode apagar -- turma que outro pedido ou outra
# inscrição ainda usa, e turma vazia que a gravação não tocou.
RSpec.describe "Turma sob demanda que a inscrição deixa vazia", type: :request do
  before(:each) do
    @level = FactoryBot.create(:level, name: "Mestrado")
    @status = FactoryBot.create(:enrollment_status, name: "Regular", user: true)
    student = FactoryBot.create(:student, name: "Ana")
    @enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M01", student: student,
      level: @level, enrollment_status: @status
    )
    @student_user = create_confirmed_user(
      [FactoryBot.create(:role_aluno)], "ana.vazia@ic.uff.br", "Ana",
      "A1b2c3d4!", student: student
    )
    @schedule = FactoryBot.create(
      :class_schedule, year: 2026, semester: 2,
      enrollment_start: 30.days.ago, enrollment_end: 20.days.ago,
      period_start: 10.days.ago, enrollment_insert: 3.days.from_now,
      enrollment_remove: 3.days.from_now
    )
    type = FactoryBot.create(
      :course_type, on_demand: true, allow_multiple_classes: false
    )
    @course = FactoryBot.create(:course, course_type: type)
    @p1 = FactoryBot.create(:professor, name: "Primeiro")
    @p2 = FactoryBot.create(:professor, name: "Segundo")
    [@p1, @p2].each do |professor|
      FactoryBot.create(
        :advisement_authorization, professor: professor, level: @level,
        start_date: Date.current - 1.day, end_date: nil
      )
    end
    @class_p1 = FactoryBot.create(
      :course_class, course: @course, professor: @p1, year: 2026, semester: 2
    )
    @pedido = FactoryBot.create(
      :enrollment_request, enrollment: @enrollment, year: 2026, semester: 2
    )
    @request_p1 = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido,
      course_class: @class_p1, action: ClassEnrollmentRequest::INSERT,
      status: ClassEnrollmentRequest::REQUESTED
    )
    allow(Notifier).to receive(:send_emails)
  end

  def page_post(selected:, professor:, others: [], delete_request: false)
    params = {
      course_class_ids: [""] + others.map { |c| c.id.to_s }, message: "",
      course_ids: {
        @course.id.to_s => { selected: selected, professor: professor.id.to_s }
      }
    }
    params[:delete_request] = "1" if delete_request
    sign_in @student_user
    post "/enrollment/#{@enrollment.id}/enroll/2026-2",
      params: { enrollment_request: params }
    sign_out @student_user
  end

  def class_p2
    CourseClass.find_by(course: @course, professor: @p2, year: 2026, semester: 2)
  end

  def eo_requests
    ClassEnrollmentRequest.joins(:course_class)
      .where(course_classes: { course_id: @course.id }).order(:id)
      .map { |cer| [cer.course_class.professor, cer.action, cer.status] }
  end

  # Outra disciplina, fora da sob demanda, pedida no mesmo pedido: com ela,
  # desmarcar a sob demanda não esvazia o pedido.
  def other_discipline
    course_class = FactoryBot.create(
      :course_class,
      course: FactoryBot.create(
        :course, course_type: FactoryBot.create(:course_type, on_demand: false)
      ),
      professor: @p1, year: 2026, semester: 2
    )
    FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido,
      course_class: course_class, action: ClassEnrollmentRequest::INSERT,
      status: ClassEnrollmentRequest::REQUESTED
    )
    course_class
  end

  # Outro aluno com pedido na turma de P1.
  def other_student_requests_p1
    enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M02",
      student: FactoryBot.create(:student, name: "Bia"),
      level: @level, enrollment_status: @status
    )
    FactoryBot.create(
      :class_enrollment_request,
      enrollment_request: FactoryBot.create(
        :enrollment_request, enrollment: enrollment, year: 2026, semester: 2
      ),
      course_class: @class_p1, action: ClassEnrollmentRequest::INSERT,
      status: ClassEnrollmentRequest::REQUESTED
    )
  end

  let(:insert) { ClassEnrollmentRequest::INSERT }
  let(:requested) { ClassEnrollmentRequest::REQUESTED }
  let(:effected) { ClassEnrollmentRequest::EFFECTED }

  describe "pedido recusado depois de escolher o professor" do
    # Do 16º ao 30º dia: a adição fechou e a remoção continua aberta. A
    # troca de P1 por P2 pede uma adição, e o pedido volta recusado.
    before(:each) do
      @request_p1.update!(status: effected)
      @schedule.update!(enrollment_insert: 1.day.ago)
    end

    it "recusa a troca e mantém P1 (controle)" do
      page_post(selected: "1", professor: @p2)

      expect(response).to have_http_status(:ok)
      expect(eo_requests).to eq([[@p1, insert, effected]])
    end

    it "não deixa a turma de P2 criada", pending: "issue #375" do
      page_post(selected: "1", professor: @p2)

      expect(class_p2).to be_nil
    end

    it "mantém a turma de P2 que já existia (controle)" do
      existing = FactoryBot.create(
        :course_class, course: @course, professor: @p2, year: 2026, semester: 2
      )

      page_post(selected: "1", professor: @p2)

      expect(CourseClass.exists?(existing.id)).to be(true)
    end
  end

  describe "pedido de P1 que sai antes da efetivação" do
    it "troca P1 por P2 numa gravação (controle)" do
      page_post(selected: "1", professor: @p2)

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests).to eq([[@p2, insert, requested]])
    end

    it "apaga a turma de P1 que a troca esvaziou", pending: "issue #375" do
      page_post(selected: "1", professor: @p2)

      expect(CourseClass.exists?(@class_p1.id)).to be(false)
    end

    it "apaga a turma de P1 que a desmarcação esvaziou",
       pending: "issue #375" do
      other = other_discipline

      page_post(selected: "0", professor: @p1, others: [other])

      expect(eo_requests).to eq([])
      expect(CourseClass.exists?(@class_p1.id)).to be(false)
    end

    it "apaga a turma de P1 ao remover o pedido inteiro",
       pending: "issue #375" do
      page_post(selected: "0", professor: @p1, delete_request: true)

      expect(EnrollmentRequest.exists?(@pedido.id)).to be(false)
      expect(CourseClass.exists?(@class_p1.id)).to be(false)
    end

    it "mantém a turma de P1 que outro aluno pediu (controle)" do
      other_student_requests_p1

      page_post(selected: "1", professor: @p2)

      expect(CourseClass.exists?(@class_p1.id)).to be(true)
    end

    it "mantém a turma fora da sob demanda que a desmarcação esvaziou " \
       "(controle)" do
      other = other_discipline

      page_post(selected: "1", professor: @p1)

      expect(ClassEnrollmentRequest.where(course_class: other)).to be_empty
      expect(CourseClass.exists?(other.id)).to be(true)
    end
  end

  describe "pedido de P1 já efetivado" do
    # A remoção efetivada fica no pedido como histórico: a turma tem pedido.
    it "mantém a turma de P1 com a remoção pedida na troca (controle)" do
      @request_p1.update!(status: effected)

      page_post(selected: "1", professor: @p2)

      expect(eo_requests).to eq(
        [[@p1, ClassEnrollmentRequest::REMOVE, requested], [@p2, insert, requested]]
      )
      expect(CourseClass.exists?(@class_p1.id)).to be(true)
    end
  end
end
