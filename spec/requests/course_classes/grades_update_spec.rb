# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Lancamento de notas pela edicao da turma (#720). Dois caminhos estavam sem
# cobertura: o e-mail ao professor, que percorre CourseClassDrop#class_enrollments
# e ClassEnrollmentDrop#full_absence_to_view, e as validacoes guardadas pela
# Ability de current_user (post_grades sem update_all_fields), que so rodam
# numa requisicao de professor.
RSpec.describe "Lancamento de notas na edicao da turma", type: :request do
  before(:each) do
    ActionMailer::Base.deliveries.clear
    @professor = FactoryBot.create(:professor, name: "Prof Turma", email: "prof_turma@ic.uff.br")
    tipo = FactoryBot.create(:course_type, has_score: true)
    curso = FactoryBot.create(:course, course_type: tipo, name: "Algoritmos")
    @turma = FactoryBot.create(:course_class, course: curso, professors: [@professor], name: "Turma A")
    @aprovada = FactoryBot.create(
      :class_enrollment, course_class: @turma,
      enrollment: FactoryBot.create(:enrollment, enrollment_number: "M-APROV",
        student: FactoryBot.create(:student, name: "Aluno Aprovado"))
    )
    @faltosa = FactoryBot.create(
      :class_enrollment, course_class: @turma,
      enrollment: FactoryBot.create(:enrollment, enrollment_number: "M-FALTA",
        student: FactoryBot.create(:student, name: "Aluno Faltoso"))
    )
    ActionMailer::Base.deliveries.clear
  end

  def lanca(inscricoes, **campos_da_turma)
    put course_class_path(@turma), params: {
      record: {
        name: @turma.name, year: @turma.year, semester: @turma.semester,
        class_enrollments: inscricoes.to_h { |i, attrs| [i.id.to_s, { id: i.id.to_s }.merge(attrs)] }
      }.merge(campos_da_turma)
    }
  end

  def notas_de_aprovado_e_reprovado_por_falta
    {
      @aprovada => { situation: ClassEnrollment::APPROVED, grade: "8.5", disapproved_by_absence: "0" },
      @faltosa => { situation: ClassEnrollment::DISAPPROVED, grade: "2.0", disapproved_by_absence: "1" }
    }
  end

  def email_ao_professor
    ActionMailer::Base.deliveries.find { |m| m.to.include?("prof_turma@ic.uff.br") }
  end

  describe "pela secretaria" do
    before(:each) do
      sign_in create_confirmed_user(
        [FactoryBot.create(:role_administrador)], "adm_notas@ic.uff.br", "Adm"
      )
    end

    it "grava as notas e avisa o professor listando cada inscricao com a falta por extenso" do
      lanca(notas_de_aprovado_e_reprovado_por_falta)

      expect(@aprovada.reload.grade).to eq(85)
      expect(@faltosa.reload.disapproved_by_absence).to be(true)
      mensagem = email_ao_professor
      corpo = (mensagem.text_part || mensagem).body.decoded
      reprovado = I18n.t("activerecord.attributes.class_enrollment.disapproved_by_absence")
      expect(corpo).to include("Aluno Aprovado")
      expect(corpo).to include("#{ClassEnrollment::APPROVED}* - 8.5* (#{I18n.t("active_scaffold.false")} #{reprovado}")
      expect(corpo).to include("Aluno Faltoso")
      expect(corpo).to include("#{ClassEnrollment::DISAPPROVED}* - 2.0* (#{reprovado}*)")
    end

    it "nao avisa o professor quando nenhuma nota muda" do
      lanca({ @aprovada => { situation: ClassEnrollment::REGISTERED } })

      expect(response).to have_http_status(:found)
      expect(email_ao_professor).to be_nil
    end
  end

  describe "pelo professor da turma" do
    before(:each) do
      FactoryBot.create(:custom_variable, variable: "professor_login_can_post_grades", value: "yes_all_semesters")
      sign_in create_confirmed_user(
        [FactoryBot.create(:role_professor)], "prof_turma@ic.uff.br", "Prof Turma", professor: @professor
      )
    end

    it "grava a nota quando so os campos permitidos mudam" do
      lanca(notas_de_aprovado_e_reprovado_por_falta)

      expect(@aprovada.reload.situation).to eq(ClassEnrollment::APPROVED)
      expect(@aprovada.grade).to eq(85)
      expect(email_ao_professor).to be_present
    end

    it "recusa a mudanca de um campo da turma e nao grava as notas" do
      lanca(notas_de_aprovado_e_reprovado_por_falta, name: "Turma Renomeada")

      expect(@turma.reload.name).to eq("Turma A")
      expect(@aprovada.reload.situation).to eq(ClassEnrollment::REGISTERED)
      expect(response.body).to include(
        CGI.escapeHTML(I18n.t("activerecord.errors.models.course_class.changes_to_disallowed_fields"))
      )
    end

    it "recusa a troca da matricula de uma inscricao" do
      outra = FactoryBot.create(:enrollment, enrollment_number: "M-OUTRA")

      lanca({ @aprovada => { enrollment: outra.id.to_s } })

      expect(@aprovada.reload.enrollment.enrollment_number).to eq("M-APROV")
    end
  end
end
