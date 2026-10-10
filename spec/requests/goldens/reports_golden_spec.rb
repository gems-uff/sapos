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

  # O processo vazio acima protege o cabeçalho; o conteúdo dos relatórios vem
  # dos grupos (dados de carta, fases em ordem inversa, campos, cartas, ranking
  # e consolidação), que só aparecem com candidaturas completas. Este cenário
  # tem duas: uma com tudo preenchido e outra só com a inscrição, para o
  # relatório mostrar também as células vazias e o "não encontrado".
  #
  # Tudo que sai no papel é fixado: o código de identificação é gerado ao acaso
  # pelo modelo, então vem dado; o hash do anexo é o MD5 do conteúdo, estável.
  describe "processo de admissão com fases, cartas e ranking" do
    before(:each) do
      template = create_admission_template("Inscrição Completa", {
        "nota" => Admissions::FormField::NUMBER,
        "anexo" => Admissions::FormField::FILE,
      })
      letter_template = create_admission_template(
        "Carta de Recomendação", { "texto" => Admissions::FormField::TEXT },
        template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
      )
      @full_process = create_closed_admission_process(
        template, simple_url: "golden-completo", name: "Mestrado Golden",
        year: 2021, semester: 1, letter_template: letter_template
      )
      phase1 = add_phase(
        @full_process, 1, name: "Análise",
        shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING }),
        member_form: create_admission_template("Parecer", { "parecer" => Admissions::FormField::STRING }),
        candidate_form: create_admission_template("Complemento", { "extra" => Admissions::FormField::STRING }),
        consolidation_form: create_consolidation_template("Consolidação", {
          "dobro" => code_field("{{ fields.nota | times: 2 }}"),
        })
      )
      phase2 = add_phase(
        @full_process, 2, name: "Entrevista",
        shared_form: create_admission_template("Entrevista", { "nota_entrevista" => Admissions::FormField::NUMBER })
      )
      reviewer = professor_user("golden-reviewer@ic.uff.br")

      ana = create_application(
        @full_process, name: "Ana Conceição", email: "ana.golden@example.com",
        token: "GOLDEN-AAAAAA-000001", admission_phase: phase2,
        fields: {
          "nota" => "8.5",
          "anexo" => { file: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png") },
        }
      )
      letter = ana.letter_requests.create!(name: "Prof. Recomendador", email: "rec@example.com", telephone: "2199")
      letter.filled_form.update!(is_filled: true)
      fill_fields(letter.filled_form, { "texto" => "Recomendo sem reservas." })
      ana.letter_requests.create!(name: "Prof. Silencioso", email: "sil@example.com")
      create_phase_result(ana, phase1, Admissions::AdmissionPhaseResult::SHARED, fields: { "obs" => "Perfil forte" })
      create_phase_result(ana, phase1, Admissions::AdmissionPhaseResult::CANDIDATE, fields: { "extra" => "Publicação aceita" })
      create_evaluation(ana, phase1, reviewer, fields: { "parecer" => "Aprovar" })
      FactoryBot.create(
        :admission_pendency, admission_application: ana, admission_phase: phase1,
        mode: Admissions::AdmissionPendency::MEMBER, user: reviewer, status: Admissions::AdmissionPendency::OK
      )
      ana.consolidate_phase!(phase1)
      create_phase_result(ana, phase2, Admissions::AdmissionPhaseResult::SHARED, fields: { "nota_entrevista" => "9" })

      create_application(
        @full_process, name: "Bento Souza", email: "bento.golden@example.com",
        token: "GOLDEN-BBBBBB-000002", fields: { "nota" => "6" }
      )
      @full_process.update!(min_letters: 1, max_letters: 2)

      ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
      ranking.ranking_columns.first.update!(order: Admissions::RankingColumn::DESC)
      FactoryBot.create(
        :admission_process_ranking, admission_process: @full_process, ranking_config: ranking, order: 1
      ).generate_ranking
    end

    it "mantém o conteúdo do baseline resumido" do
      get short_pdf_admission_process_path(@full_process, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "admission_process_full_short", response.body, format: :pdf
      )
    end

    it "mantém o conteúdo do baseline completo" do
      get complete_pdf_admission_process_path(@full_process, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "admission_process_full_complete", response.body, format: :pdf
      )
    end

    it "mantém as células do baseline em XLSX" do
      get complete_xls_admission_process_path(@full_process, format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "admission_process_full_complete_xls", response.body, format: :xlsx
      )
    end
  end

  # A prévia não tem rota GET: é POST, monta um ReportConfiguration em memória a
  # partir de record_params e renderiza sem persistir. record_id -1 é o sinal de
  # "registro novo" que o controller usa.
  describe "prévia da configuração de relatório" do
    it "mantém o conteúdo do baseline" do
      post preview_report_configurations_path(format: :pdf), params: {
        record_id: -1,
        record: {
          name: "Configuração Golden",
          text: "UNIVERSIDADE FEDERAL FLUMINENSE",
          scale: 1,
          signature_type: "no_signature",
          use_at_report: true
        }
      }

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "report_configuration_preview", response.body, format: :pdf
      )
    end
  end

  # O external_report_pdf não é uma ação: é renderizado no before_create_save do
  # ReportsController, via ReportsHelper#create_external_report_pdf, e o corpo
  # passa pelo formatador Liquid. Cobri-lo exige criar o documento e baixá-lo --
  # o que, de quebra, exercita o liquid dentro da geração de PDF.
  describe "documento externo" do
    before(:each) do
      # O identificador do documento é sorteado (PdfHelper#generate_qr_code_key)
      # e sai IMPRESSO no PDF, na URL de acesso -- então o baseline mudava a cada
      # execução. Fixar o gerador é o mesmo raciocínio do relógio congelado:
      # tira o acaso e mantém o formato visível, de modo que uma mudança no
      # formato do identificador ainda seria detectada.
      allow_any_instance_of(PdfHelper)
        .to receive(:generate_qr_code_key).and_return("GOLDN-00001")
    end

    it "mantém o conteúdo do baseline" do
      post reports_path, params: {
        record: {
          file_name: "documento-golden",
          document_title: "Declaração",
          document_body: "Declaramos para os devidos fins.",
          expiration_in_months: ""
        }
      }

      report = Report.order(:id).last
      expect(report).to be_present

      # set_report busca por Report.find_by_identifier, não pelo hash do arquivo.
      # E o .pdf é literal na rota (/reports/:identifier.pdf), então passar
      # format: :pdf o duplicaria.
      get "/reports/#{report.identifier}.pdf"

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "external_report", response.body, format: :pdf
      )
    end
  end

  # O cenário básico do `before` deixa metade de enrollments_pdf_helper.rb sem
  # executar: tese e banca, desligamento, prorrogação, etapas cumpridas (com e
  # sem data), bolsa com suspensão e cancelamento, nota que não conta no CR e
  # observação no histórico só aparecem quando a matrícula tem esses dados. Este
  # bloco monta a matrícula "cheia" e gera um segundo baseline de cada PDF, para
  # que um upgrade de prawn ou uma mudança no helper não passe em branco nesses
  # ramos. Os baselines básicos continuam valendo para a matrícula "vazia".
  describe "histórico e boletim de matrícula com todos os blocos" do
    before(:each) do
      # Estado com o mesmo nome do órgão emissor: é o ramo que rotula o campo
      # como "UF" em vez de "país" no cabeçalho do aluno.
      country = FactoryBot.create(:country, name: "Brasil")
      FactoryBot.create(:state, name: "Rio de Janeiro", code: "RJ", country: country)
      @student.update!(
        birthdate: Date.new(1990, 5, 10),
        identity_number: "12.345.678-9",
        identity_issuing_place: "Rio de Janeiro"
      )

      # Etapas ligadas ao nível da matrícula ANTES de criar accomplishment e
      # deferral: as factories dos dois trocam o nível da matrícula pelo da
      # etapa quando a etapa não tem nível, o que mudaria o cabeçalho.
      language = FactoryBot.create(:phase, name: "Proficiência em Inglês", is_language: true)
      qualification = FactoryBot.create(:phase, name: "Exame de Qualificação")
      defense = FactoryBot.create(:phase, name: "Defesa")
      [language, qualification, defense].each do |phase|
        FactoryBot.create(:phase_duration, phase: phase, level: @level)
      end
      FactoryBot.create(
        :accomplishment, enrollment: @enrollment, phase: language,
        conclusion_date: Date.new(2020, 12, 1)
      )
      # Sem data de conclusão: é o ramo "data não informada" do boletim. O modelo
      # exige a data (e a factory preenche com hoje quando falta), então o ramo
      # só é alcançável por dado legado -- daí o update_column, que não valida.
      FactoryBot.create(
        :accomplishment, enrollment: @enrollment, phase: qualification,
        conclusion_date: Date.new(2021, 2, 1)
      ).update_column(:conclusion_date, nil)
      deferral_type = FactoryBot.create(
        :deferral_type, name: "Prorrogação de Defesa", phase: defense
      )
      FactoryBot.create(
        :deferral, enrollment: @enrollment, deferral_type: deferral_type,
        approval_date: Date.new(2021, 1, 10)
      )

      # Duas disciplinas cuja nota não conta no CR: uma com justificativa e uma
      # sem, para o ramo do texto de "não informado".
      [["TCC00002", "Tópicos Especiais", "Disciplina isolada"],
       ["TCC00003", "Seminários", ""]].each do |code, name, justification|
        course = FactoryBot.create(
          :course, name: name, code: code, course_type: @course_type,
          credits: 2, workload: 30
        )
        course_class = FactoryBot.create(
          :course_class, course: course, professor: @professor, year: 2020, semester: 2
        )
        FactoryBot.create(
          :class_enrollment, course_class: course_class, enrollment: @enrollment,
          situation: ClassEnrollment::APPROVED, grade: 80,
          grade_not_count_in_gpr: true,
          justification_grade_not_count_in_gpr: justification
        )
      end

      # Bolsa encerrada por cancelamento, com uma suspensão ativa e uma inativa;
      # tem de estar encerrada antes do desligamento, que recusa bolsa vigente.
      sponsor = FactoryBot.create(:sponsor, name: "CNPq")
      scholarship = FactoryBot.create(
        :scholarship, sponsor: sponsor, level: @level,
        scholarship_number: "B2020002",
        start_date: Date.new(2020, 3, 1), end_date: Date.new(2022, 2, 28)
      )
      duration = FactoryBot.create(
        :scholarship_duration, enrollment: @enrollment, scholarship: scholarship,
        start_date: Date.new(2020, 3, 1), end_date: Date.new(2021, 2, 28),
        cancel_date: Date.new(2020, 12, 31)
      )
      FactoryBot.create(
        :scholarship_suspension, scholarship_duration: duration, active: true,
        start_date: Date.new(2020, 6, 1), end_date: Date.new(2020, 7, 31)
      )
      FactoryBot.create(
        :scholarship_suspension, scholarship_duration: duration, active: false,
        start_date: Date.new(2020, 9, 1), end_date: Date.new(2020, 9, 30)
      )

      # Orientador, banca com afiliação e tese defendida; o motivo de
      # desligamento mostra o orientador, que é o que liga o bloco no histórico.
      FactoryBot.create(:advisement_authorization, professor: @professor, level: @level)
      FactoryBot.create(
        :advisement, professor: @professor, enrollment: @enrollment, main_advisor: true
      )
      institution = FactoryBot.create(:institution, name: "Universidade Federal Fluminense")
      %w[Maria\ Silva Carlos\ Souza].each do |name|
        member = FactoryBot.create(:professor, name: name)
        FactoryBot.create(
          :affiliation, professor: member, institution: institution,
          start_date: Date.new(2010, 1, 1), end_date: nil
        )
        FactoryBot.create(
          :thesis_defense_committee_participation,
          professor: member, enrollment: @enrollment
        )
      end
      @enrollment.update!(
        thesis_title: "Rastreabilidade em Sistemas de Software",
        thesis_defense_date: Date.new(2021, 3, 15),
        obs_to_academic_transcript: "Aluno com aproveitamento de créditos."
      )
      reason = FactoryBot.create(
        :dismissal_reason, name: "Titulação",
        thesis_judgement: DismissalReason::APPROVED, show_advisor_name: true
      )
      FactoryBot.create(
        :dismissal, enrollment: @enrollment, dismissal_reason: reason,
        date: Date.new(2021, 3, 20)
      )
    end

    it "mantém o conteúdo do baseline do histórico escolar completo" do
      get academic_transcript_pdf_enrollment_path(@enrollment, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "enrollment_academic_transcript_full", response.body, format: :pdf
      )
    end

    it "mantém o conteúdo do baseline do boletim completo" do
      get grades_report_pdf_enrollment_path(@enrollment, format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "enrollment_grades_report_full", response.body, format: :pdf
      )
    end
  end

  # search_table só desenha quando a busca vem preenchida, e ela chega ao PDF
  # pela sessão (search_params do active_scaffold), como no quadro de horários.
  # A busca completa passa também pelas condições customizadas do
  # EnrollmentSearchConcern, que a lista sem filtro nunca executa. Toda chave
  # aninhada precisa existir, porque o helper as indexa sem checar.
  describe "relatório de matrículas com busca preenchida" do
    it "mantém o conteúdo do baseline dos filtros e da lista" do
      # A etapa cumprida faz a matrícula do cenário casar com o filtro de
      # "realização de etapa", para a lista sair com uma linha e não vazia.
      phase = FactoryBot.create(:phase, name: "Exame de Qualificação")
      FactoryBot.create(:phase_duration, phase: phase, level: @level)
      FactoryBot.create(
        :accomplishment, enrollment: @enrollment, phase: phase,
        conclusion_date: Date.new(2021, 1, 15)
      )

      get enrollments_path(search: {
        enrollment_number: "M2020001",
        student: @student.id.to_s,
        level: @level.id.to_s,
        enrollment_status: @enrollment_status.id.to_s,
        admission_date: { month: "3", year: "2020" },
        active: "all",
        scholarship_durations_active: "",
        professor: "",
        accomplishments: { phase: phase.id.to_s, day: "15", month: "6", year: "2021" },
        delayed_phase: { phase: "", day: "", month: "", year: "" },
        course_class_year_semester: { year: "2020", semester: "1", course: "" },
        research_area: "",
        research_line: "",
        enrollment_hold: { hold: "0", active: "" }
      })
      get to_pdf_enrollments_path(format: :pdf)

      expect(response).to have_http_status(:ok)
      expect_matches_golden(
        "enrollments_list_with_search", response.body, format: :pdf
      )
    end
  end
end
