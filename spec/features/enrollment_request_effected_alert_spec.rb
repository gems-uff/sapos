# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# O formulário do pedido de inscrição avisa, quando a secretaria tira de
# Efetivada uma linha que estava efetivada antes da alteração, que a
# inscrição será removida ou recriada (effected-change-alert). A página
# devolvida por uma gravação recusada traz a escolha enviada: se ela tirou
# uma linha de Efetivada, o aviso vale desde que a página abre, e não só
# depois que a secretaria mexer de novo naquela linha.
#
# Cenário da recusa: o aluno pediu X (disciplina C) e Y (disciplina D); Y foi
# efetivada; depois a nota de C foi revista para aprovado, e X deixa de poder
# ser efetivada (previously_approved).
RSpec.describe "Pedido de inscrição: aviso de pedido já efetivado", type: :feature, js: true do
  requested = ClassEnrollmentRequest::REQUESTED
  effected = ClassEnrollmentRequest::EFFECTED

  before(:each) do
    enrollment = FactoryBot.create(
      :enrollment, level: FactoryBot.create(:level),
      enrollment_status: FactoryBot.create(:enrollment_status, user: true)
    )
    FactoryBot.create(
      :class_schedule, year: 2026, semester: 2,
      enrollment_start: 30.days.ago, enrollment_end: 20.days.ago,
      period_start: 10.days.ago, enrollment_insert: 3.days.from_now,
      enrollment_remove: 3.days.from_now
    )
    type = FactoryBot.create(:course_type, on_demand: false, allow_multiple_classes: false)
    course_c = FactoryBot.create(:course, name: "Calculo", course_type: type)
    professor = FactoryBot.create(:professor)
    x = FactoryBot.create(:course_class, course: course_c, professor: professor, year: 2026, semester: 2)
    y = FactoryBot.create(
      :course_class, course: FactoryBot.create(:course, name: "Dados", course_type: type),
      professor: professor, year: 2026, semester: 2
    )
    anterior = ClassEnrollment.create!(
      enrollment: enrollment, situation: ClassEnrollment::DISAPPROVED,
      course_class: FactoryBot.create(
        :course_class, course: course_c, professor: professor, year: 2026, semester: 1
      )
    )
    @pedido = FactoryBot.create(:enrollment_request, enrollment: enrollment, year: 2026, semester: 2)
    @cx = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: x,
      action: ClassEnrollmentRequest::INSERT, status: requested
    )
    @cy = FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido, course_class: y,
      action: ClassEnrollmentRequest::INSERT, status: requested
    )
    expect(@cy.set_status!(effected)).to be(true)
    anterior.update_columns(situation: ClassEnrollment::APPROVED)

    login_as(create_confirmed_user([FactoryBot.create(:role_administrador)]))
    visit edit_enrollment_request_path(@pedido)
  end

  def escolhe(cer, status)
    choose("record[class_enrollment_requests][#{cer.id}][status]", option: status)
  end

  it "controle: a página recém-aberta não mostra o aviso" do
    expect(page).to have_css(".enroll-table")
    expect(page).to have_no_css(".effected-change-alert", visible: :visible)
  end

  it "controle: tirar de Efetivada a linha efetivada mostra o aviso" do
    escolhe(@cy, requested)

    expect(page).to have_css(".effected-change-alert", visible: :visible)
  end

  it "a página devolvida pela recusa mostra o aviso da linha tirada de Efetivada" do
    escolhe(@cx, effected)
    escolhe(@cy, requested)
    click_button_and_wait "Salvar"

    expect(page).to have_content(
      I18n.t("activerecord.errors.models.class_enrollment_request.attributes.course_class.previously_approved")
    )
    expect(@cy.reload.status).to eq(effected)
    expect(page).to have_css(".effected-change-alert", visible: :visible)
  end
end
