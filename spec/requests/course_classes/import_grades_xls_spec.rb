# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Estes exemplos descrevem o que a importacao de notas precisa fazer, e hoje
# falham -- sao o criterio de aceitacao do conserto, nao um retrato do que esta
# implementado. Cada bloco diz, junto, qual e o defeito que o faz falhar.
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

  # Reproduz a pauta que o proprio sistema exporta, com a coluna de nota
  # preenchida por fora -- o caminho descrito na issue.
  def pauta(class_enrollment, nota:, frequencia: ClassEnrollment::ATTENDANCE_TRUE,
            situacao: nil, arquivo: "pauta.xlsx")
    pacote = Axlsx::Package.new
    pacote.workbook.add_worksheet(name: "Pauta da Turma") do |sheet|
      sheet.add_row cabecalho
      sheet.add_row [
        1, class_enrollment.enrollment.enrollment_number, "aluno", "aluno@test.com",
        nota, frequencia, situacao || class_enrollment.situation, nil, "Nao",
        I18n.l(class_enrollment.created_at, format: :defaultdatetime)
      ]
    end
    tempfile = Tempfile.new(["pauta", File.extname(arquivo)])
    tempfile.binmode
    tempfile.write(pacote.to_stream.read)
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, nil, false, original_filename: arquivo)
  end

  def enviar(class_enrollment, **kwargs)
    post import_grades_xls_course_class_path(turma),
      params: { spreadsheet: pauta(class_enrollment, **kwargs) }
  end

  def confirmar_o_que_foi_previsto
    payload = Nokogiri::HTML(response.body).css('input[name="changes"]').first
    post import_grades_xls_course_class_path(turma),
      params: { confirm: "1", changes: payload&.[]("value") }
  end

  def politica_de_lancamento(valor)
    variavel = CustomVariable.find_or_initialize_by(
      variable: "professor_login_can_post_grades"
    )
    variavel.value = valor
    variavel.save(validate: false)
  end

  context "como administrador" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
    end

    # A situacao vem da planilha como "Incompleto" -- e o que o proprio export
    # escreve para quem ainda nao tem nota. Cabe a importacao recalcular para
    # "Aprovado" a partir da nota, e hoje ela nao recalcula: compara a nota da
    # planilha ("8,7", escala de exibicao) com minimum_grade_for_approval (60,
    # escala interna). Como nao recalcula, a validacao recusa nota com situacao
    # "Incompleto"; e como apply_xls_import_changes ignora o retorno de save,
    # o erro vira uma linha de log e a tela anuncia sucesso.
    it "grava a nota preenchida na planilha" do
      enviar(inscricao, nota: "8,7")
      confirmar_o_que_foi_previsto

      expect(inscricao.reload.grade).to eq(87)
    end

    it "recalcula a situacao a partir da nota" do
      enviar(inscricao, nota: "8,7")
      confirmar_o_que_foi_previsto

      expect(inscricao.reload.situation).to eq(ClassEnrollment::APPROVED)
    end

    it "nao anuncia sucesso quando nada foi gravado" do
      enviar(inscricao, nota: "8,7")
      confirmar_o_que_foi_previsto

      anunciou_sucesso = flash[:info].present?
      expect(anunciou_sucesso).to eq(inscricao.reload.grade.present?)
    end

    # Coluna "Freq S/I" vazia cai em class_enrollment.attendance, que nao existe
    # no modelo -- ha disapproved_by_absence e attendance_to_label.
    it "aceita planilha com a coluna de frequencia em branco" do
      enviar(inscricao, nota: "8,7", frequencia: nil)

      expect(response.status).to be < 500
    end

    # parse_rows_xls levanta ArgumentError e ninguem trata. A chave de locale
    # import_grades_xls_error existe e nao tem consumidor.
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

    # A lista branca aceita .xls, mas o roo 3.x so le OOXML; ler BIFF exigiria a
    # gem roo-xls, que nao esta no Gemfile.lock. O rotulo do formulario ja diz
    # apenas ".xlsx".
    it "recusa .xls com aviso, e nao com erro de servidor" do
      enviar(inscricao, nota: "8,7", arquivo: "pauta.xls")

      expect(response.status).to be < 500
    end

    # current_grade sai de class_enrollment[:grade], que e o inteiro cru, e a
    # nota nova sai da planilha na escala de exibicao: a tabela mostra "87" ao
    # lado de "9,0".
    it "mostra nota atual e nota nova na mesma escala" do
      inscricao.update!(grade: 87, situation: ClassEnrollment::APPROVED)
      enviar(inscricao, nota: "9,0", situacao: ClassEnrollment::APPROVED)

      celulas = Nokogiri::HTML(response.body).css("tbody td").map { |td| td.text.strip }
      expect(celulas[2]).to eq("8,7")
    end

    # O status vem como simbolo (:not_enrolled) enquanto os outros dois sao
    # strings, e a view compara com string: a celula sai vazia e o aviso de
    # aluno nao inscrito nunca aparece.
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
      confirmar_o_que_foi_previsto

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

    # authorize_resource roda antes da acao, quando @course_class ainda e nil, e
    # por isso autoriza a classe CourseClass em vez da turma; a condicao
    # professor: user.professor nunca chega a ser avaliada. O corpo da acao faz
    # CourseClass.find(params[:id]) sem nenhuma conferencia, e o payload de
    # confirmacao volta do navegador e e gravado como veio -- por isso o ataque
    # dispensa planilha.
    it "nao deixa professor de outra turma gravar nota" do
      politica_de_lancamento("yes_all_semesters")
      entrar_como(outro_professor, "outro@ic.uff.br")

      post import_grades_xls_course_class_path(turma), params: {
        confirm: "1",
        changes: [{
          class_enrollment_id: inscricao.id, status: "pending",
          final_grade: "9.0", final_attendance: true,
          final_situation: ClassEnrollment::APPROVED, final_obs: "de fora"
        }].to_json
      }

      expect(inscricao.reload.grade).to be_nil
    end

    # A regra foi parar em Ability#initialize_professors, solta da politica
    # professor_login_can_post_grades que condiciona todo o resto do lancamento
    # de notas em initialize_courses.
    it "respeita a politica que desliga o lancamento de notas por professor" do
      politica_de_lancamento("no")
      entrar_como(professor_da_turma, "titular@ic.uff.br")

      post import_grades_xls_course_class_path(turma), params: {
        confirm: "1",
        changes: [{
          class_enrollment_id: inscricao.id, status: "pending",
          final_grade: "9.0", final_attendance: true,
          final_situation: ClassEnrollment::APPROVED, final_obs: nil
        }].to_json
      }

      expect(inscricao.reload.grade).to be_nil
    end
  end
end
