# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Estes exemplos descrevem o que a importacao de notas precisa fazer. Os do
# contexto "como administrador" e "como professor" ja passam, e ficam como
# guarda: a cadeia de calculo, a escala da nota e a autorizacao por turma sao o
# que eles travam.
RSpec.describe "Importacao de notas por planilha", type: :request do
  let(:course_type) { FactoryBot.create(:course_type, has_score: true) }
  let(:course) { FactoryBot.create(:course, course_type: course_type) }
  let(:turma) { FactoryBot.create(:course_class, course: course) }
  let(:enrollment) { FactoryBot.create(:enrollment) }
  let(:inscricao) do
    FactoryBot.create(
      :class_enrollment, course_class: turma, enrollment: enrollment,
      grade: nil, situation: ClassEnrollment::REGISTERED
    )
  end

  def cabecalho
    %w[sequential_number enrollment_number student_name student_email final_grade
       attendance situation obs active_scholarship created_at].map do |chave|
      I18n.t("xls_content.course_class.summary.#{chave}")
    end
  end

  # Uma linha da pauta que o proprio sistema exporta, com a coluna de nota
  # preenchida por fora -- o caminho descrito na issue.
  def linha(class_enrollment, nota:, frequencia: ClassEnrollment::ATTENDANCE_TRUE,
            situacao: nil, obs: nil)
    [
      1, class_enrollment.enrollment.enrollment_number, "aluno", "aluno@test.com",
      nota, frequencia, situacao || class_enrollment.situation, obs, "Nao",
      I18n.l(class_enrollment.created_at, format: :defaultdatetime)
    ]
  end

  def pauta_de_linhas(linhas, arquivo: "pauta.xlsx")
    pacote = Axlsx::Package.new
    pacote.workbook.add_worksheet(name: "Pauta da Turma") do |sheet|
      sheet.add_row cabecalho
      linhas.each { |uma| sheet.add_row uma }
    end
    tempfile = Tempfile.new(["pauta", File.extname(arquivo)])
    tempfile.binmode
    tempfile.write(pacote.to_stream.read)
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, nil, false, original_filename: arquivo)
  end

  def pauta(class_enrollment, arquivo: "pauta.xlsx", **kwargs)
    pauta_de_linhas([linha(class_enrollment, **kwargs)], arquivo: arquivo)
  end

  def enviar(class_enrollment, **kwargs)
    post import_grades_xls_course_class_path(turma),
      params: { spreadsheet: pauta(class_enrollment, **kwargs) }
  end

  # A previa fica guardada na sessao; o passo de confirmacao nao carrega payload
  # nenhum, e e justamente isso que impede o navegador de ditar o que e gravado.
  def confirmar(turma_alvo = turma)
    post import_grades_xls_course_class_path(turma_alvo), params: { confirm: "1" }
  end

  def variavel_customizada(nome, valor)
    variavel = CustomVariable.find_or_initialize_by(variable: nome)
    variavel.value = valor
    variavel.save(validate: false)
  end

  def politica_de_lancamento(valor)
    variavel_customizada("professor_login_can_post_grades", valor)
  end

  def celulas_da_previa
    Nokogiri::HTML(response.body).css("tbody td").map { |td| td.text.strip }
  end

  context "como administrador" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
    end

    # A situacao vem da planilha como "Incompleto" -- e o que o proprio export
    # escreve para quem ainda nao tem nota. Cabe a importacao recalcular para
    # "Aprovado" a partir da nota, e para isso os dois lados da comparacao tem
    # de estar na mesma escala: a planilha entrega "8,7" (exibicao) e
    # minimum_grade_for_approval devolve 60 (interna, x10). Sem o recalculo a
    # validacao recusaria nota com situacao "Incompleto".
    it "grava a nota preenchida na planilha" do
      enviar(inscricao, nota: "8,7")
      confirmar

      expect(inscricao.reload.grade).to eq(87)
    end

    it "recalcula a situacao a partir da nota" do
      enviar(inscricao, nota: "8,7")
      confirmar

      expect(inscricao.reload.situation).to eq(ClassEnrollment::APPROVED)
    end

    it "nao anuncia sucesso quando nada foi gravado" do
      enviar(inscricao, nota: "8,7")
      confirmar

      anunciou_sucesso = flash[:info].present?
      expect(anunciou_sucesso).to eq(inscricao.reload.grade.present?)
    end

    # Coluna "Freq S/I" vazia nao pode cair em class_enrollment.attendance, que
    # nao existe no modelo -- ha disapproved_by_absence e attendance_to_label.
    it "aceita planilha com a coluna de frequencia em branco" do
      enviar(inscricao, nota: "8,7", frequencia: nil)

      expect(response.status).to be < 500
    end

    # parse_rows_xls levanta ArgumentError, e a acao tem de traduzir isso na
    # chave de locale import_grades_xls_error em vez de deixar subir.
    it "avisa em vez de estourar quando o arquivo nao e planilha" do
      texto = Tempfile.new(["nota", ".txt"])
      texto.write("nao sou uma planilha")
      texto.rewind
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: Rack::Test::UploadedFile.new(
          texto.path, nil, false, original_filename: "nota.txt"
        )
      }

      expect(response.status).to be < 500
    end

    # O roo 3.x so le OOXML; ler BIFF exigiria a gem roo-xls, que nao esta no
    # Gemfile.lock. Por isso .xls fica fora da lista branca -- o rotulo do
    # formulario ja diz apenas ".xlsx".
    it "recusa .xls com aviso, e nao com erro de servidor" do
      enviar(inscricao, nota: "8,7", arquivo: "pauta.xls")

      expect(response.status).to be < 500
    end

    # A nota nova sai da planilha na escala de exibicao, entao a nota atual tem
    # de sair de grade_to_view e nao do inteiro cru -- senao a tabela mostra
    # "87" ao lado de "9,0".
    it "mostra nota atual e nota nova na mesma escala" do
      inscricao.update!(grade: 87, situation: ClassEnrollment::APPROVED)
      enviar(inscricao, nota: "9,0", situacao: ClassEnrollment::APPROVED)

      expect(celulas_da_previa[2]).to eq("8,7")
    end

    # O status tem de ser string como os outros dois ("not_found", "pending"),
    # porque e assim que a view compara; simbolo deixa a celula vazia e o aviso
    # de aluno nao inscrito nunca aparece.
    it "identifica na previa o aluno que nao esta inscrito na turma" do
      outra_turma = FactoryBot.create(:course_class, course: course)
      de_fora = FactoryBot.create(
        :class_enrollment, course_class: outra_turma, grade: nil,
        situation: ClassEnrollment::REGISTERED
      )
      post import_grades_xls_course_class_path(turma),
        params: { spreadsheet: pauta(de_fora, nota: "8,7") }

      expect(response.body).to include("Aluno não inscrito")
    end

    it "ignora valores forjados no payload de confirmacao, usando os calculados no servidor" do
      enviar(inscricao, nota: "8,7")

      post import_grades_xls_course_class_path(turma), params: {
        confirm: "1",
        changes: [{
          class_enrollment_id: inscricao.id, status: "pending",
          final_grade: "999", final_attendance: true,
          final_situation: ClassEnrollment::APPROVED, final_obs: "forjado"
        }].to_json
      }

      expect(inscricao.reload.grade).to eq(87)
      expect(inscricao.reload.obs).not_to eq("forjado")
    end

    it "nao marca divergencia quando a nota final bate com a informada" do
      enviar(inscricao, nota: "6,5", situacao: ClassEnrollment::APPROVED)

      conteudo = Nokogiri::HTML(response.body)
      celula_nota_nova = conteudo.css("tbody td")[4]
      expect(celula_nota_nova.text).not_to include("*")
    end

    it "rebaixa a situacao quando a nota informada nao sustenta o aprovado da planilha" do
      enviar(inscricao, nota: "1,0", situacao: ClassEnrollment::APPROVED)
      confirmar

      expect(inscricao.reload.situation).to eq(ClassEnrollment::DISAPPROVED)
    end

    it "ignora situacao invalida vinda da planilha e mantem a atual" do
      enviar(inscricao, nota: "8,7", situacao: "Cancelado")

      expect(response.body).to include("não é uma situação válida")
    end
  end

  context "como professor" do
    let(:professor_da_turma) { turma.professor }
    let(:outro_professor) { FactoryBot.create(:professor) }

    def entrar_como(professor, email)
      role = FactoryBot.create(:role_professor)
      sign_in create_confirmed_user(
        [role], email, "prof", "A1b2c3d4!", professor: professor
      )
    end

    # A autorizacao tem de ser avaliada sobre a turma, nao sobre a classe:
    # authorize_resource roda antes da acao, quando @course_class ainda e nil, e
    # o CanCan nao tem como avaliar "professor: user.professor" sobre uma classe
    # -- deixa passar. Por isso a acao carrega a turma e chama authorize! sobre
    # ela.
    #
    # A recusa aparece como 500, porque CanCan::AccessDenied nao tem mapeamento
    # em rescue_responses (mesmo registro de spec/requests/assertion_authorization_spec.rb).
    #
    # O envio da pauta e o passo que precisa ser barrado: e por ele que a previa
    # entra na sessao, e sem previa na sessao o passo de confirmacao nao tem o
    # que gravar. Afirmar so o segundo passo daria verde mesmo com a autorizacao
    # arrancada.
    it "nao deixa professor de outra turma nem chegar a previa" do
      politica_de_lancamento("yes_all_semesters")
      entrar_como(outro_professor, "outro@ic.uff.br")

      enviar(inscricao, nota: "9,0")

      expect(response.status).to eq(500)
    end

    it "nao deixa professor de outra turma gravar nota" do
      politica_de_lancamento("yes_all_semesters")
      entrar_como(outro_professor, "outro@ic.uff.br")

      enviar(inscricao, nota: "9,0")
      confirmar

      expect(inscricao.reload.grade).to be_nil
    end

    # Controle: o titular da turma, com a politica ligada, atravessa os dois
    # passos. Sem ele, o vermelho acima nao distingue autorizacao viva de
    # cenario mal montado.
    it "deixa o titular da turma gravar quando a politica permite" do
      politica_de_lancamento("yes_all_semesters")
      entrar_como(professor_da_turma, "titular@ic.uff.br")

      enviar(inscricao, nota: "9,0")
      confirmar

      expect(inscricao.reload.grade).to eq(90)
    end

    # A regra vive em Ability#initialize_courses, condicionada a
    # professor_login_can_post_grades como todo o resto do lancamento de notas
    # -- e nao solta em initialize_professors, onde a politica nao alcanca.
    it "respeita a politica que desliga o lancamento de notas por professor" do
      politica_de_lancamento("no")
      entrar_como(professor_da_turma, "titular@ic.uff.br")

      enviar(inscricao, nota: "9,0")
      confirmar

      expect(inscricao.reload.grade).to be_nil
    end
  end
end
