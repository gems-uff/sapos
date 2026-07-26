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
    # As factories do projeto usam data relativa (3.days.ago, YearSemester.current)
    # porque 26 arquivos de spec dependem de "vigente agora". Trocá-las por data
    # fixa mudaria a semântica de todos eles. A previsibilidade que estes testes
    # precisam vem daqui: o relógio congela, e o que a factory calcula em cima de
    # `now` passa a ser determinístico sem que a factory mude.
    travel_to GoldenMaster::FROZEN_AT

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

  after(:each) { travel_back }

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

  describe "resumo da turma em PDF" do
    it "mantém o conteúdo do baseline" do
      get summary_pdf_course_class_path(@course_class, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "course_class_summary_pdf", response.body, format: :pdf
      )
    end
  end

  describe "relatório de matrículas" do
    it "mantém o conteúdo do baseline" do
      get to_pdf_enrollments_path(format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "enrollments_list", response.body, format: :pdf
      )
    end
  end

  # Os cenários abaixo criam registros próprios em vez de estender o `before`
  # compartilhado: uma bolsa ligada a @enrollment apareceria no histórico escolar
  # e invalidaria aquele baseline. Cada relatório monta só o que consome.
  describe "relatório de orientações" do
    before(:each) do
      # Sem o credenciamento no nível da matrícula o Advisement é inválido
      # ("Ao menos um orientador deve ter credenciamento no nível da matrícula").
      FactoryBot.create(
        :advisement_authorization, professor: @professor, level: @level
      )
      FactoryBot.create(
        :advisement, professor: @professor, enrollment: @enrollment,
        main_advisor: true
      )
    end

    it "mantém o conteúdo do baseline" do
      get to_pdf_advisements_path(format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "advisements_list", response.body, format: :pdf
      )
    end
  end

  describe "relatório de bolsas" do
    before(:each) do
      # Datas fixas: a factory usa 3.days.ago/from_now, e data relativa tornaria
      # o baseline dependente do dia em que a suíte roda.
      @sponsor = FactoryBot.create(:sponsor, name: "CAPES")
      @scholarship = FactoryBot.create(
        :scholarship,
        sponsor: @sponsor,
        level: @level,
        scholarship_number: "B2020001",
        start_date: Date.new(2020, 3, 1),
        end_date: Date.new(2022, 2, 28)
      )
    end

    it "mantém o conteúdo do baseline" do
      get to_pdf_scholarships_path(format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "scholarships_list", response.body, format: :pdf
      )
    end

    it "mantém o conteúdo do baseline das durações" do
      FactoryBot.create(
        :scholarship_duration,
        enrollment: @enrollment,
        scholarship: @scholarship,
        start_date: Date.new(2020, 3, 1),
        end_date: Date.new(2022, 2, 28)
      )

      get to_pdf_scholarship_durations_path(format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "scholarship_durations_list", response.body, format: :pdf
      )
    end
  end

  describe "quadro de horários" do
    before(:each) do
      @class_schedule = FactoryBot.create(
        :class_schedule, year: 2020, semester: 1
      )
    end

    it "mantém o conteúdo do baseline por período" do
      get class_schedule_pdf_class_schedule_path(@class_schedule, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "class_schedule", response.body, format: :pdf
      )
    end

    it "mantém o conteúdo do baseline da listagem de turmas" do
      # Sem ano e semestre a ação recusa e redireciona (flash de erro em
      # pdf_content.class_schedule.class_schedule_pdf). O active_scaffold guarda
      # a busca na sessão -- store_search_params_into_session --, então é preciso
      # buscar primeiro e só depois pedir o PDF.
      get course_classes_path(search: { year: "2020", semester: "1" })
      get class_schedule_pdf_course_classes_path(format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "course_classes_schedule", response.body, format: :pdf
      )
    end
  end

  describe "processo de admissão" do
    before(:each) do
      # simple_url próprio: a factory usa "mestrado" fixo, e o AdmissionProcess
      # recusa duas URLs iguais em intervalos que se sobrepõem. Rodando a suíte
      # inteira, outro spec já deixou esse valor no banco -- isolado passava,
      # junto quebrava. O golden não pode depender de banco vazio.
      @admission_process = FactoryBot.create(
        :admission_process, simple_url: "golden-mestrado"
      )
    end

    it "mantém o conteúdo do baseline resumido" do
      get short_pdf_admission_process_path(@admission_process, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "admission_process_short", response.body, format: :pdf
      )
    end

    it "mantém o conteúdo do baseline completo" do
      get complete_pdf_admission_process_path(@admission_process, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "admission_process_complete", response.body, format: :pdf
      )
    end

    it "mantém as células do baseline em XLSX" do
      get complete_xls_admission_process_path(@admission_process, format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "admission_process_complete_xls", response.body, format: :xlsx
      )
    end
  end
end
