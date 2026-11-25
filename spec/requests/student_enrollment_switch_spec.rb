# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Troca de professor em disciplina sob demanda que não permite mais de uma
# inscrição (#781). Com a inscrição em P1 efetivada, a página deixa o aluno
# desmarcar P1 e escolher P2 na mesma gravação: o pedido fica com a remoção de
# P1 e a adição de P2 solicitadas. Na efetivação a regra continua estrita --
# nunca duas inscrições ativas na disciplina --, então a adição só sai depois da
# remoção, e o lote e o formulário da secretaria efetivam na ordem certa.
RSpec.describe "Troca de professor em disciplina sob demanda", type: :request do
  before(:each) do
    @level = FactoryBot.create(:level, name: "Mestrado")
    status = FactoryBot.create(:enrollment_status, name: "Regular", user: true)
    student = FactoryBot.create(:student, name: "Ana")
    @enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M01", student: student,
      level: @level, enrollment_status: status
    )
    @student_user = create_confirmed_user(
      [FactoryBot.create(:role_aluno)], "ana.sapos@ic.uff.br", "Ana",
      "A1b2c3d4!", student: student
    )
    @admin = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm.troca@ic.uff.br", "Adm"
    )
    # Ajuste aberto para adição e remoção; inscrição principal encerrada.
    FactoryBot.create(
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
    @removal = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido,
      course_class: @class_p1, action: ClassEnrollmentRequest::INSERT,
      status: ClassEnrollmentRequest::EFFECTED
    )
    allow(Notifier).to receive(:send_emails)
  end

  def class_p2
    CourseClass.find_by(course: @course, professor: @p2, year: 2026, semester: 2)
  end

  def insertion
    ClassEnrollmentRequest.find_by(course_class: class_p2)
  end

  def enrolled_professors
    ClassEnrollment.where(enrollment: @enrollment)
      .map { |class_enrollment| class_enrollment.course_class.professor }
  end

  def message(key)
    ClassEnrollmentRequest.new.errors.full_message(
      :course_class,
      I18n.t(
        "activerecord.errors.models.class_enrollment_request.attributes." \
        "course_class.#{key}"
      )
    )
  end

  # O envio da página: a linha de P1 desmarcada e o seletor com P2.
  def switch_to_p2
    sign_in @student_user
    post "/enrollment/#{@enrollment.id}/enroll/2026-2", params: {
      enrollment_request: {
        course_class_ids: [""], message: "",
        course_ids: {
          @course.id.to_s => { selected: "1", professor: @p2.id.to_s }
        }
      }
    }
    sign_out @student_user
    @removal.reload
  end

  describe "na página do aluno" do
    it "aceita a troca numa gravação e deixa as duas metades solicitadas" do
      switch_to_p2

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(@removal.action).to eq(ClassEnrollmentRequest::REMOVE)
      expect(@removal.status).to eq(ClassEnrollmentRequest::REQUESTED)
      expect(insertion.action).to eq(ClassEnrollmentRequest::INSERT)
      expect(insertion.status).to eq(ClassEnrollmentRequest::REQUESTED)
      expect(enrolled_professors).to eq([@p1])
    end

    # O caminho que já funcionava: pedir a remoção, a secretaria efetivá-la,
    # e só então pedir P2. Controle do cenário, verde antes da #781.
    it "troca em duas etapas, com a remoção efetivada no meio (controle)" do
      sign_in @student_user
      post "/enrollment/#{@enrollment.id}/enroll/2026-2", params: {
        enrollment_request: {
          course_class_ids: [""], message: "", delete_request: "1",
          course_ids: {
            @course.id.to_s => { selected: "0", professor: @p1.id.to_s }
          }
        }
      }
      sign_out @student_user
      sign_in @admin
      put set_effected_class_enrollment_request_path(@removal)
      sign_out @admin
      switch_to_p2
      sign_in @admin
      put set_effected_class_enrollment_request_path(insertion)

      expect(@removal.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(@removal.action).to eq(ClassEnrollmentRequest::REMOVE)
      expect(insertion.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(enrolled_professors).to eq([@p2])
    end
  end

  describe "na efetivação" do
    before(:each) do
      switch_to_p2
      sign_in @admin
    end

    it "recusa a adição antes da remoção, dizendo para remover primeiro" do
      put set_effected_class_enrollment_request_path(insertion)

      expect(insertion.status).to eq(ClassEnrollmentRequest::REQUESTED)
      expect(flash[:error]).to eq([message(:remove_first)])
      expect(enrolled_professors).to eq([@p1])
    end

    it "efetiva a adição depois da remoção" do
      put set_effected_class_enrollment_request_path(@removal)
      put set_effected_class_enrollment_request_path(insertion)

      expect(@removal.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(insertion.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(enrolled_professors).to eq([@p2])
    end

    it "efetiva as duas pelo lote, mesmo com a adição listada antes" do
      get class_enrollment_requests_path,
        params: { sort: "action", sort_direction: "ASC" }
      post effect_class_enrollment_requests_path

      expect(@removal.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(insertion.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(enrolled_professors).to eq([@p2])
    end

    it "efetiva as duas pelo formulário do pedido, na mesma gravação" do
      put enrollment_request_path(@pedido), params: {
        record: {
          comment_message: "",
          class_enrollment_requests: {
            "0" => "",
            @removal.id.to_s => {
              id: @removal.id.to_s,
              course_class: @removal.course_class_id.to_s,
              class_enrollment: @removal.class_enrollment_id.to_s,
              status: ClassEnrollmentRequest::EFFECTED
            },
            insertion.id.to_s => {
              id: insertion.id.to_s,
              course_class: insertion.course_class_id.to_s,
              class_enrollment: "",
              status: ClassEnrollmentRequest::EFFECTED
            }
          }
        }
      }

      expect(@removal.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(insertion.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(enrolled_professors).to eq([@p2])
    end

    # A remoção efetivada libera a adição porque apagou a inscrição. Se a
    # inscrição voltou depois (recriada pela tela de inscrições), o status da
    # remoção não vale mais: efetivar a adição deixaria duas inscrições, e a
    # da adição seria recusada em silêncio.
    it "recusa a adição se a inscrição removida voltou pela tela de inscrições" do
      put set_effected_class_enrollment_request_path(@removal)
      post class_enrollments_path, params: {
        record: {
          enrollment: @enrollment.id.to_s, course_class: @class_p1.id.to_s,
          situation: ClassEnrollment::REGISTERED
        }
      }
      expect(enrolled_professors).to eq([@p1])

      put set_effected_class_enrollment_request_path(insertion)

      expect(insertion.status).to eq(ClassEnrollmentRequest::REQUESTED)
      expect(insertion.class_enrollment).to be_nil
      expect(flash[:error]).to eq([message(:already_enrolled)])
      expect(enrolled_professors).to eq([@p1])
    end

    # Desfazer a remoção efetivada recria a inscrição removida. Com a adição
    # da troca já efetivada, a inscrição recriada seria a segunda na
    # disciplina e não grava: a recusa tem de chegar à secretaria, e a remoção
    # continuar efetivada.
    it "recusa desfazer a remoção depois da troca efetivada" do
      put set_effected_class_enrollment_request_path(@removal)
      put set_effected_class_enrollment_request_path(insertion)

      put set_requested_class_enrollment_request_path(@removal)

      expect(@removal.reload.status).to eq(ClassEnrollmentRequest::EFFECTED)
      expect(flash[:error]).to eq([
        ClassEnrollment.new.errors.full_message(
          :course_class,
          I18n.t(
            "activerecord.errors.models.class_enrollment.attributes." \
            "course_class.multiple_class_enrollments_not_allowed"
          )
        )
      ])
      expect(enrolled_professors).to eq([@p2])
    end

    it "desfaz a remoção efetivada antes da adição, recriando a inscrição (controle)" do
      put set_effected_class_enrollment_request_path(@removal)

      put set_requested_class_enrollment_request_path(@removal)

      expect(@removal.reload.status).to eq(ClassEnrollmentRequest::REQUESTED)
      expect(@removal.class_enrollment).to be_present
      expect(enrolled_professors).to eq([@p1])
    end

    it "com a remoção negada, recusa a adição pela inscrição registrada" do
      put set_invalid_class_enrollment_request_path(@removal)
      put set_effected_class_enrollment_request_path(insertion)

      expect(insertion.status).to eq(ClassEnrollmentRequest::REQUESTED)
      expect(flash[:error]).to eq([message(:already_enrolled)])
      expect(enrolled_professors).to eq([@p1])
    end
  end

  # Sem remoção pendente, a recusa diz o que a inscrição existente é.
  # A tabela verdade da #781: pedido de P1 efetivado ou não, janela de ajuste
  # aberta (adição e remoção) ou fechada, troca em uma ou duas gravações. Nas
  # duas gravações, a primeira desmarca P1; com P1 efetivado, a secretaria
  # efetiva a remoção antes da segunda, que pede P2.
  describe "tabela verdade da troca" do
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

    def page_errors
      Nokogiri::HTML(response.body).css("#error_explanation li")
        .map { |li| li.text.squish }
    end

    def eo_requests
      ClassEnrollmentRequest.joins(:course_class)
        .where(course_classes: { course_id: @course.id }).order(:id)
        .map { |cer| [cer.course_class.professor, cer.action, cer.status] }
    end

    def staff_effects_removals
      ClassEnrollmentRequest.where(
        action: ClassEnrollmentRequest::REMOVE,
        status: ClassEnrollmentRequest::REQUESTED
      ).find_each do |cer|
        cer.set_status!(ClassEnrollmentRequest::EFFECTED)
      end
    end

    def p1_not_effected!
      @removal.update!(status: ClassEnrollmentRequest::REQUESTED)
    end

    def close_window!
      ClassSchedule.find_by(year: 2026, semester: 2).update!(
        enrollment_insert: 1.day.ago, enrollment_remove: 1.day.ago
      )
    end

    # Outra disciplina no pedido, no mesmo status de P1: com ela, desmarcar
    # P1 não esvazia o pedido.
    def other_discipline
      course_class = FactoryBot.create(
        :course_class,
        course: FactoryBot.create(
          :course,
          course_type: FactoryBot.create(:course_type, on_demand: false)
        ),
        professor: @p1, year: 2026, semester: 2
      )
      FactoryBot.create(
        :class_enrollment_request, enrollment_request: @pedido,
        course_class: course_class, action: ClassEnrollmentRequest::INSERT,
        status: @removal.reload.status
      )
      course_class
    end

    def closed_alert
      I18n.t(
        "student_enrollment.alert.closed_enrollment", year: "2026", semester: "2"
      )
    end

    let(:insert) { ClassEnrollmentRequest::INSERT }
    let(:remove) { ClassEnrollmentRequest::REMOVE }
    let(:requested) { ClassEnrollmentRequest::REQUESTED }
    let(:effected) { ClassEnrollmentRequest::EFFECTED }

    it "1. não efetivado, janela aberta, uma gravação: troca" do
      p1_not_effected!

      page_post(selected: "1", professor: @p2)

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests).to eq([[@p2, insert, requested]])
    end

    it "2. não efetivado, janela aberta, duas gravações, EO sozinho: " \
       "desmarcar pede 'Remover pedido?'" do
      p1_not_effected!

      page_post(selected: "0", professor: @p1)
      expect(response).to have_http_status(:ok)
      expect(eo_requests).to eq([[@p1, insert, requested]])

      page_post(selected: "0", professor: @p1, delete_request: true)
      expect(eo_requests).to eq([])

      page_post(selected: "1", professor: @p2)
      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests).to eq([[@p2, insert, requested]])
    end

    it "2. não efetivado, janela aberta, duas gravações, com outra disciplina" do
      p1_not_effected!
      other = other_discipline

      page_post(selected: "0", professor: @p1, others: [other])
      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests).to eq([])

      page_post(selected: "1", professor: @p2, others: [other])
      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests).to eq([[@p2, insert, requested]])
    end

    it "3. não efetivado, janela fechada, uma gravação: recusa" do
      p1_not_effected!
      close_window!

      page_post(selected: "1", professor: @p2)

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(flash[:alert]).to eq(closed_alert)
      expect(eo_requests).to eq([[@p1, insert, requested]])
    end

    it "4. não efetivado, janela fechada, duas gravações: recusa as duas" do
      p1_not_effected!
      close_window!

      page_post(selected: "0", professor: @p1, delete_request: true)
      expect(flash[:alert]).to eq(closed_alert)
      page_post(selected: "1", professor: @p2)
      expect(flash[:alert]).to eq(closed_alert)

      expect(eo_requests).to eq([[@p1, insert, requested]])
    end

    it "5. efetivado, janela aberta, uma gravação: remoção e adição pedidas" do
      page_post(selected: "1", professor: @p2)

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests)
        .to eq([[@p1, remove, requested], [@p2, insert, requested]])
    end

    it "6. efetivado, janela aberta, duas gravações, EO sozinho: " \
       "desmarcar pede 'Solicitar remoção do pedido?'" do
      page_post(selected: "0", professor: @p1)
      expect(response).to have_http_status(:ok)
      expect(eo_requests).to eq([[@p1, insert, effected]])

      page_post(selected: "0", professor: @p1, delete_request: true)
      expect(eo_requests).to eq([[@p1, remove, requested]])

      staff_effects_removals
      page_post(selected: "1", professor: @p2)
      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests)
        .to eq([[@p1, remove, effected], [@p2, insert, requested]])
    end

    it "6. efetivado, janela aberta, duas gravações, com outra disciplina" do
      other = other_discipline

      page_post(selected: "0", professor: @p1, others: [other])
      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests).to eq([[@p1, remove, requested]])

      staff_effects_removals
      page_post(selected: "1", professor: @p2, others: [other])
      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(eo_requests)
        .to eq([[@p1, remove, effected], [@p2, insert, requested]])
    end

    it "7. efetivado, janela fechada, uma gravação: recusa" do
      close_window!

      page_post(selected: "1", professor: @p2)

      expect(response).to redirect_to(student_enrollment_path(@enrollment.id))
      expect(flash[:alert]).to eq(closed_alert)
      expect(eo_requests).to eq([[@p1, insert, effected]])
    end

    it "8. efetivado, janela fechada, duas gravações: recusa as duas" do
      close_window!

      page_post(selected: "0", professor: @p1, delete_request: true)
      expect(flash[:alert]).to eq(closed_alert)
      page_post(selected: "1", professor: @p2)
      expect(flash[:alert]).to eq(closed_alert)

      expect(eo_requests).to eq([[@p1, insert, effected]])
    end

    # Fora dos 8: só a adição aberta. Sem remoção não há troca, e a recusa
    # diz por quê.
    it "efetivado, só a adição aberta, uma gravação: recusa explicando" do
      ClassSchedule.find_by(year: 2026, semester: 2)
        .update!(enrollment_remove: 1.day.ago)

      page_post(selected: "1", professor: @p2)

      expect(response).to have_http_status(:ok)
      expect(page_errors).to include(message(:already_enrolled))
      expect(eo_requests).to eq([[@p1, insert, effected]])
    end
  end

  # Aprovado num semestre anterior, o aluno não pede a disciplina de novo.
  describe "disciplina aprovada em semestre anterior" do
    it "recusa com a mensagem de aprovação (controle)" do
      @removal.class_enrollment.update!(situation: ClassEnrollment::APPROVED)
      other_request = FactoryBot.create(
        :enrollment_request, enrollment: @enrollment, year: 2027, semester: 1
      )
      cer = ClassEnrollmentRequest.new(
        enrollment_request: EnrollmentRequest.find(other_request.id),
        course_class: FactoryBot.create(
          :course_class, course: @course, professor: @p2,
          year: 2027, semester: 1
        ),
        action: ClassEnrollmentRequest::INSERT,
        status: ClassEnrollmentRequest::REQUESTED
      )

      expect(cer).not_to be_valid
      expect(cer.errors.details[:course_class])
        .to include(error: :previously_approved)
    end
  end
end
