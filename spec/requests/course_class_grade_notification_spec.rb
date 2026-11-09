# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Editar a turma mudando a nota de uma inscricao manda um resumo ao professor
# (CourseClassesController#before_update_save). Nenhum exemplo editava turma com
# inscricoes (#720).
RSpec.describe "Edicao de turma com inscricoes", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.turma.nota@ic.uff.br", "Adm")
    com_nota = FactoryBot.create(:course, course_type: FactoryBot.create(:course_type, has_score: true))
    @turma = FactoryBot.create(
      :course_class, course: com_nota, professors: [FactoryBot.create(:professor, email: "prof.turma@ic.uff.br")]
    )
    @inscricao = FactoryBot.create(:class_enrollment, course_class: @turma)
    @enviados = []
    allow(Notifier).to receive(:send_emails) { |notifications:| @enviados.concat(notifications) }
  end

  def atualizar(campos)
    patch course_class_path(@turma), params: {
      record: { class_enrollments: { @inscricao.id.to_s => campos.merge(id: @inscricao.id) } },
    }
  end

  def ao_professor
    @enviados.select { |m| m[:to] == "prof.turma@ic.uff.br" }
  end

  it "manda ao professor um resumo da turma quando uma nota muda" do
    atualizar(situation: ClassEnrollment::APPROVED, grade: "9.0")

    expect(response).to redirect_to(course_classes_path)
    expect(@inscricao.reload.grade).to eq(90)
    expect(ao_professor.size).to eq(1)
    expect(ao_professor.first[:subject]).to eq("Alteração de notas em #{@turma.label_for_email_subject}")
  end

  it "nao manda nada quando nenhuma inscricao muda" do
    atualizar(situation: @inscricao.situation)

    expect(response).to redirect_to(course_classes_path)
    expect(@enviados).to be_empty
  end

  # Com inscricao invalida o resumo nao sai: o formulario volta com o erro.
  it "nao manda o resumo quando a inscricao alterada e invalida" do
    atualizar(situation: ClassEnrollment::APPROVED, grade: "2.0")

    expect(response).to have_http_status(:ok)
    expect(@inscricao.reload.grade).to be_nil
    expect(ao_professor).to be_empty
  end
end
