# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Estes exemplos descrevem o que a importacao de notas precisa fazer. Os do
# contexto "como administrador" e "como professor" ja passam, e ficam como
# guarda: a cadeia de calculo, a escala da nota e a autorizacao por turma sao o
# que eles travam. Os do contexto "defeitos em aberto" falham -- sao o criterio
# de aceitacao do proximo conserto, e cada um diz junto qual e a causa.
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

  # Estes falham. Sao os defeitos que a rodada de revisao confirmou por
  # reproducao, e ficam aqui como criterio de aceitacao do proximo conserto.
  context "defeitos em aberto" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
      variavel_customizada("grade_of_disapproval_for_absence", "1,0")
    end

    # A comparacao com ATTENDANCE_TRUE ("S") e exata, e nada sinaliza o valor
    # que nao casa -- ao contrario da coluna de situacao, que tem
    # invalid_situation. Qualquer outra grafia ("Sim", "s", "P", "1") e lida
    # como ausencia: a nota da planilha e descartada, entra
    # grade_of_disapproval_for_absence, a situacao vira "Reprovado" e a tela
    # anuncia sucesso.
    it "nao reprova por falta com valor de frequencia que nao reconhece" do
      enviar(inscricao, nota: "8,7", frequencia: "Sim")
      confirmar

      expect(inscricao.reload.disapproved_by_absence).to be_falsey
    end

    it "preserva a nota da planilha quando a frequencia vem em outra grafia" do
      enviar(inscricao, nota: "8,7", frequencia: "Sim")
      confirmar

      expect(inscricao.reload.grade).to eq(87)
    end

    # String#to_f devolve 0.0 para o que nao comeca por numero, e a celula e
    # present?, entao "-", "N/A" ou "falta" entram como 0,0 e o recalculo poe
    # "Reprovado". Zero que nunca apareceu na planilha.
    it "nao transforma nota nao numerica em zero" do
      enviar(inscricao, nota: "N/A")
      confirmar

      expect(inscricao.reload.grade).not_to eq(0)
    end

    # O rescue cobre ArgumentError, que parse_rows_xls levanta antes de abrir o
    # arquivo. Quem renomeia um .xls ou um .csv para .xlsx passa da lista branca
    # e o roo levanta Zip::Error de dentro, que ninguem trata.
    it "avisa em vez de estourar quando o .xlsx nao e um zip valido" do
      falso = Tempfile.new(["falso", ".xlsx"])
      falso.write("nao sou um zip")
      falso.rewind
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: Rack::Test::UploadedFile.new(
          falso.path, nil, false, original_filename: "falso.xlsx"
        )
      }

      expect(response.status).to be < 500
    end

    # params[:confirm] e conferido antes de request.post?, e a rota aceita GET.
    # Requisicao GET nao passa pela verificacao de token do
    # protect_from_forgery, entao a gravacao fica alcancavel por um GET
    # disparado de fora, enquanto houver previa pendente na sessao.
    it "nao aplica a importacao por GET" do
      enviar(inscricao, nota: "8,7")

      get import_grades_xls_course_class_path(turma), params: { confirm: "1" }

      expect(inscricao.reload.grade).to be_nil
    end

    # grade_not_count_in_gpr e o que permite "Aprovado" com nota abaixo do
    # minimo, com justificativa -- e o recalculo da importacao passa por cima
    # dele, mesmo quando a coluna de nota vem vazia.
    it "nao desfaz o aprovado com nota que nao conta no CR" do
      inscricao.update!(
        grade: 10, situation: ClassEnrollment::APPROVED,
        grade_not_count_in_gpr: true,
        justification_grade_not_count_in_gpr: "convalidacao"
      )
      enviar(inscricao, nota: nil, situacao: ClassEnrollment::APPROVED)
      confirmar

      expect(inscricao.reload.situation).to eq(ClassEnrollment::APPROVED)
    end

    # Em disciplina sem nota, a reprovacao por falta poe
    # grade_of_disapproval_for_absence na nota, e a validacao
    # grade_filled_for_course_without_score recusa o registro inteiro. A
    # previa mostra a linha como "Pronto".
    it "importa a reprovacao por falta em disciplina sem nota" do
      tipo = FactoryBot.create(:course_type, has_score: false)
      turma_sem_nota = FactoryBot.create(
        :course_class, course: FactoryBot.create(:course, course_type: tipo)
      )
      sem_nota = FactoryBot.create(
        :class_enrollment, course_class: turma_sem_nota,
        grade: nil, situation: ClassEnrollment::REGISTERED
      )
      post import_grades_xls_course_class_path(turma_sem_nota), params: {
        spreadsheet: pauta_de_linhas([
          linha(sem_nota, nota: nil, frequencia: ClassEnrollment::ATTENDANCE_FALSE)
        ])
      }
      confirmar(turma_sem_nota)

      expect(sem_nota.reload.disapproved_by_absence).to eq(true)
    end

    # apply_xls_import_changes manda os erros de validacao para
    # Rails.logger.debug e devolve so a contagem do que entrou. Com 2 linhas,
    # uma valida e uma recusada, a tela anuncia "1 nota(s) importada(s) com
    # sucesso!" e nao ha como saber qual ficou de fora.
    it "diz que alguma linha nao foi gravada" do
      recusada = FactoryBot.create(
        :class_enrollment, course_class: turma,
        grade: nil, situation: ClassEnrollment::REGISTERED
      )
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_linhas([
          linha(inscricao, nota: "8,7"),
          linha(recusada, nota: "99,0")
        ])
      }
      confirmar

      expect(flash[:error]).to be_present
    end

    # O laco de apply_xls_import_changes grava registro a registro, sem
    # transacao. O gatilho concreto e o after_save da propria inscricao:
    # notify_student_and_advisor termina em mail.deliver!, sincrono, uma vez por
    # aluno dentro da mesma requisicao -- SMTP que cai no meio da pauta deixa
    # gravada a parte que ja passou, e nada registra onde parou.
    it "nao aplica metade da importacao quando uma linha estoura" do
      segunda = FactoryBot.create(
        :class_enrollment, course_class: turma,
        grade: nil, situation: ClassEnrollment::REGISTERED
      )
      envios = 0
      allow(Notifier).to receive(:send_emails) do
        envios += 1
        raise Net::SMTPServerBusy, "conexao caiu no meio da pauta" if envios == 2
      end

      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_linhas([
          linha(inscricao, nota: "8,7"),
          linha(segunda, nota: "9,0")
        ])
      }
      begin
        confirmar
      rescue Net::SMTPServerBusy
        nil
      end

      expect(inscricao.reload.grade).to be_nil
    end
  end
end
