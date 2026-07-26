# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Testes de caracterização das saídas binárias — issue #636.
#
# Não afirmam que o relatório está CORRETO; afirmam que ele continua IGUAL ao
# baseline. É o que protege upgrade de prawn/caxlsx e, adiante, o salto do
# Rails 8, já que a suíte de features só confere o nome do arquivo baixado.
#
# Tudo que chega à saída é fixado explicitamente: as factories usam `sequence`
# para nome e código, e um contador variando entre execuções tornaria o baseline
# instável. Datas seguem o mesmo raciocínio — nada de YearSemester.current.
RSpec.describe "Saídas em PDF e XLSX", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm], "golden_admin@ic.uff.br")
    sign_in @user

    @level = FactoryBot.create(:level, name: "Mestrado")
    @enrollment_status = FactoryBot.create(:enrollment_status, name: "Regular")

    # Nome acentuado de propósito: é o caso que separa SQLite de MariaDB na
    # ordenação, e o que mais aparece num sistema em português.
    @student = FactoryBot.create(
      :student, name: "Ana Conceição", cpf: "000.000.000-00"
    )
    @enrollment = FactoryBot.create(
      :enrollment,
      enrollment_number: "M2020001",
      student: @student,
      level: @level,
      enrollment_status: @enrollment_status,
      admission_date: Date.new(2020, 3, 1)
    )

    # has_score: sem ele o ClassEnrollment recusa a nota ("disciplina não possui
    # nota"), e o histórico sairia sem a coluna que mais importa.
    @course_type = FactoryBot.create(
      :course_type, name: "Obrigatória", has_score: true
    )
    @course = FactoryBot.create(
      :course,
      name: "Engenharia de Software",
      code: "TCC00001",
      course_type: @course_type,
      credits: 4,
      workload: 60
    )
    @professor = FactoryBot.create(:professor, name: "João Pereira")
    @course_class = FactoryBot.create(
      :course_class,
      course: @course,
      professor: @professor,
      year: 2020,
      semester: 1
    )
    @class_enrollment = FactoryBot.create(
      :class_enrollment,
      course_class: @course_class,
      enrollment: @enrollment,
      situation: ClassEnrollment::APPROVED,
      grade: 90
    )
  end

  describe "histórico escolar" do
    it "mantém o conteúdo do baseline" do
      get academic_transcript_pdf_enrollment_path(@enrollment, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "enrollment_academic_transcript", response.body, format: :pdf
      )
    end
  end

  describe "boletim" do
    it "mantém o conteúdo do baseline" do
      get grades_report_pdf_enrollment_path(@enrollment, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "enrollment_grades_report", response.body, format: :pdf
      )
    end
  end

  describe "resumo da turma em XLSX" do
    it "mantém as células do baseline" do
      get summary_xls_course_class_path(@course_class, format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "course_class_summary", response.body, format: :xlsx
      )
    end
  end
end
