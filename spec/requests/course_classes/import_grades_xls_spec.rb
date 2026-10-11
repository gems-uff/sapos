# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Estes exemplos descrevem o que a importacao de notas precisa fazer. Quase
# todos ja passam, e ficam como guarda: a cadeia de calculo, a escala da nota,
# os valores que a planilha pode trazer, a autorizacao por turma e o que a
# previa recusa sao o que eles travam. O ultimo contexto, "defeitos em aberto",
# falha -- e o criterio de aceitacao do proximo conserto, e cada exemplo diz
# junto qual e a causa.
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
  # Leva so o token da previa que a tela mostrou, como o botao "Aceitar".
  def confirmar(turma_alvo = turma)
    token = Nokogiri::HTML(response.body).at_css("input[name=token]")&.[]("value")
    post import_grades_xls_course_class_path(turma_alvo),
      params: { confirm: "1", token: token }
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

  # Estas mecanicas ja funcionam: o recalculo na confirmacao usa o estado
  # atual do banco, nao o que a previa mostrou, e a previa expira depois de
  # um tempo. Os exemplos abaixo travam os dois comportamentos.
  context "revalidacao da previa ao confirmar" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
    end

    # Entre o envio da planilha e a confirmacao, o registro pode ter mudado
    # por outra via -- edicao manual, outra importacao, outro navegador. A
    # confirmacao recalcula a partir do estado atual do banco; quando esse
    # recalculo diverge do que a previa mostrou, a importacao nao e aplicada
    # as cegas -- a tela volta com aviso, e quem confirma decide de novo
    # sobre dados atualizados, nao sobre a fotografia antiga.
    it "nao aplica a previa quando o registro mudou no banco antes da confirmacao" do
      enviar(inscricao, nota: "8,7")

      # simula uma edicao concorrente, fora do fluxo de importacao
      inscricao.update!(grade: 50, situation: ClassEnrollment::DISAPPROVED)

      confirmar

      expect(inscricao.reload.grade).to eq(50)
      expect(flash[:warning]).to be_present
      expect(response.body).to include(
        I18n.t("xls_content.course_class.import_grades_xls_results.data_changed_warning")
      )
    end

    # Depois do aviso de divergencia, a previa continua na sessao com o
    # estado atualizado -- nao se perde, so pede confirmacao de novo. Sem
    # nova mudanca concorrente no meio, a segunda confirmacao aplica
    # normalmente.
    it "aplica na segunda confirmacao quando nao ha nova divergencia" do
      enviar(inscricao, nota: "8,7")
      inscricao.update!(grade: 10, situation: ClassEnrollment::DISAPPROVED)

      confirmar
      confirmar

      expect(inscricao.reload.grade).to eq(87)
    end

    # A previa nao expira por conta propria, mas nao pode ficar valida para
    # sempre: quem abre a tela e demora alem do tempo limite tem de refazer
    # o envio, para nao confirmar contra um estado de banco que pode ser de
    # horas antes.
    it "recusa a confirmacao quando a previa passou do tempo limite" do
      enviar(inscricao, nota: "8,7")

      travel_to(Time.current + CustomVariable.import_grades_session_timeout + 1.second) do
        confirmar
      end

      expect(inscricao.reload.grade).to be_nil
      expect(flash[:error]).to eq(I18n.t("xls_content.course_class.import_grades_xls_expired"))
    end

    # Controle: dentro do tempo limite, a mesma previa continua valida.
    it "aceita a confirmacao dentro do tempo limite" do
      enviar(inscricao, nota: "8,7")

      travel_to(Time.current + CustomVariable.import_grades_session_timeout - 1.second) do
        confirmar
      end

      expect(inscricao.reload.grade).to eq(87)
    end
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

  # Guardas de conserto: cada um travou um defeito que a importacao ja teve, e
  # o comentario diz o invariante que ele mantem, nao a causa antiga.
  context "valores da planilha e caminhos de recusa" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
      variavel_customizada("grade_of_disapproval_for_absence", "1,0")
    end

    # A coluna de frequencia so reconhece ATTENDANCE_TRUE ("S") e
    # ATTENDANCE_FALSE ("I"). Qualquer outra grafia ("Sim", "s", "P", "1") e
    # valor invalido, marcado como tal na previa: nao vira ausencia, e nao
    # descarta a nota que veio na planilha.
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

    # A nota passa por conferencia numerica antes de ser usada: "-", "N/A" ou
    # "falta" sao valor invalido, nao zero. String#to_f devolveria 0.0 para
    # todos eles, e o recalculo poria "Reprovado" com um zero que a planilha
    # nunca trouxe.
    it "nao transforma nota nao numerica em zero" do
      enviar(inscricao, nota: "N/A")
      confirmar

      expect(inscricao.reload.grade).not_to eq(0)
    end

    # Passar da lista branca de extensao nao garante que o arquivo seja uma
    # planilha: quem renomeia um .xls ou um .csv para .xlsx faz o roo levantar
    # Zip::Error de dentro do open. Isso tem de virar aviso, nao 500.
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

    # A rota aceita GET para exibir o formulario, e GET e dispensado da
    # verificacao de token do protect_from_forgery. Por isso a gravacao exige
    # request.post? ANTES de olhar params[:confirm]: senao ficaria alcancavel
    # por um GET disparado de fora, enquanto houver previa pendente na sessao.
    it "nao aplica a importacao por GET" do
      enviar(inscricao, nota: "8,7")

      get import_grades_xls_course_class_path(turma), params: { confirm: "1" }

      expect(inscricao.reload.grade).to be_nil
    end

    # grade_not_count_in_gpr e o que permite "Aprovado" com nota abaixo do
    # minimo, com justificativa. O recalculo da importacao respeita essa
    # decisao de secretaria, inclusive quando a coluna de nota vem vazia e a
    # nota reusada e a que ja estava gravada.
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

    # Em disciplina sem nota, a reprovacao por falta nao pode escrever
    # grade_of_disapproval_for_absence na nota: a validacao
    # grade_filled_for_course_without_score recusaria o registro inteiro. O
    # recalculo consulta course_has_grade, como o modelo faz.
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

    # A notificacao saiu de dentro da gravacao: o laco salva com
    # skip_notification e so depois, fora da transacao, chama
    # notify_student_and_advisor. Por isso SMTP que cai no meio da pauta nao
    # desfaz nem interrompe o que ja foi gravado -- avisa por flash.
    it "salva as notas mesmo quando o envio de e-mail falha no meio da pauta" do
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
      confirmar

      expect(inscricao.reload.grade).to eq(87)
      expect(segunda.reload.grade).to eq(90)
      expect(flash[:warning]).to be_present
    end

    it "nao aplica nenhuma ocorrencia de matricula duplicada na planilha" do
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_linhas([
          linha(inscricao, nota: "8,7"),
          linha(inscricao, nota: "5,0")
        ])
      }
      confirmar

      expect(inscricao.reload.grade).to be_nil
    end
  end

  # O que a previa recusa e como a confirmacao reage. Cada exemplo foi medido
  # com controle quando ainda era reproducao: fica vermelho com a causa de
  # volta.
  context "recusas e avisos da previa" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
    end

    # import_grades_session_timeout e em minutos, e o getter devolve Duration
    # tanto no default quanto com a variavel configurada -- quem chama faz
    # `.ago`, que Integer nao tem. Sao os unicos exemplos que configuram a
    # variavel.
    it "nao estoura quando o tempo limite esta configurado" do
      variavel_customizada("import_grades_session_timeout", "60")
      enviar(inscricao, nota: "8,7")

      confirmar

      expect(response.status).to be < 500
    end

    it "grava a nota quando o tempo limite esta configurado" do
      variavel_customizada("import_grades_session_timeout", "60")
      enviar(inscricao, nota: "8,7")

      confirmar

      expect(inscricao.reload.grade).to eq(87)
    end

    # A coluna de nota e inteira, na escala interna (x10), entao so uma casa
    # decimal cabe -- e `ClassEnrollment#grade=` converte apenas String, de
    # modo que um Float com mais casas truncaria em silencio. Valor com mais de
    # uma casa e recusado, como os nao numericos, e nao arredondado: a nota
    # gravada e sempre a que alguem escreveu. O controle e o exemplo "grava a
    # nota preenchida na planilha", com uma casa, no contexto de administrador.
    it "recusa nota com mais de uma casa decimal em vez de truncar" do
      enviar(inscricao, nota: "0,29", situacao: ClassEnrollment::REGISTERED)
      confirmar

      expect(inscricao.reload.grade).to be_nil
    end

    it "nao anuncia na previa a nota com mais de uma casa decimal" do
      enviar(inscricao, nota: "0,29", situacao: ClassEnrollment::REGISTERED)

      expect(celulas_da_previa[4]).not_to include("0,29")
    end

    # A previa e o unico lugar onde da para conferir antes de gravar, entao
    # "Pronto" significa "esta linha grava". A previa roda as validacoes do
    # modelo sobre os valores finais e marca como invalida a linha que a
    # gravacao recusaria: aqui, nota fora de 0..10 (grade_gt_100).
    it "nao marca como pronta a linha com nota acima do maximo" do
      enviar(inscricao, nota: "99,0", situacao: ClassEnrollment::REGISTERED)

      expect(celulas_da_previa[1]).not_to eq(
        I18n.t("xls_content.course_class.import_grades_xls_results.status_pending")
      )
    end

    # Mesmo ponto, por outra causa: coluna de nota vazia com situacao
    # "Aprovado" passa pelo recalculo intocada (o `elsif final_grade.present?`
    # nao roda), e so a validacao do modelo (grade_for_situation) a recusa.
    it "nao marca como pronta a linha que a validacao vai recusar" do
      enviar(inscricao, nota: nil, situacao: ClassEnrollment::APPROVED)

      expect(celulas_da_previa[1]).not_to eq(
        I18n.t("xls_content.course_class.import_grades_xls_results.status_pending")
      )
    end

    # O erro volta para a tela de upload, que nao e view de active_scaffold --
    # o _messages da gem nao roda ali. Sem a mensagem, o professor ve o
    # formulario vazio de novo, sem uma palavra sobre o que houve.
    it "mostra na tela o erro de arquivo invalido" do
      texto = Tempfile.new(["nota", ".txt"])
      texto.write("nao sou uma planilha")
      texto.rewind
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: Rack::Test::UploadedFile.new(
          texto.path, nil, false, original_filename: "nota.txt"
        )
      }
      follow_redirect!

      expect(response.body).to include(
        I18n.t("xls_content.course_class.import_grades_xls_error")
      )
    end

    # A duplicidade e conferida antes da existencia: matricula repetida que nao
    # existe no banco sai como duplicada, que e o que o professor tem de
    # corrigir na planilha.
    it "reporta como duplicada a matricula repetida que nao existe no banco" do
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_linhas([
          [1, "NAO-EXISTE", "aluno", "a@t.com", "8,7",
           ClassEnrollment::ATTENDANCE_TRUE, nil, nil, "Nao", "01/01/2026 00:00"],
          [2, "NAO-EXISTE", "aluno", "a@t.com", "5,0",
           ClassEnrollment::ATTENDANCE_TRUE, nil, nil, "Nao", "01/01/2026 00:00"]
        ])
      }

      expect(response.body).to include(
        I18n.t("xls_content.course_class.import_grades_xls_results.status_duplicate")
      )
    end

    # A notificacao roda depois da gravacao. Servidor de e-mail fora do ar
    # (Errno::ECONNREFUSED) nao e erro de SMTP, e se subisse o usuario
    # receberia 500 sobre uma importacao que deu certo -- e reenviaria,
    # notificando de novo quem ja recebeu.
    it "nao estoura quando o servidor de e-mail recusa a conexao" do
      allow(Notifier).to receive(:send_emails).and_raise(Errno::ECONNREFUSED)
      enviar(inscricao, nota: "8,7")

      confirmar

      expect(response.status).to be < 500
    end

    # Duas grafias da mesma matricula. O que conta como "mesma" e decisao da
    # collation do banco, nao do String#hash do Ruby: em producao
    # (utf8mb4_unicode_ci) "m01" e "M01 " sao a matricula "M01" -- caixa
    # ignorada, espaco no fim ignorado. Por isso a duplicidade e conferida
    # sobre a inscricao resolvida, nao sobre a string da celula; sem isso a
    # previa mostraria duas linhas "Pronto" para um aluno so, e a ultima
    # venceria na gravacao.
    #
    # O exemplo so roda no adaptador de producao: no SQLite as duas grafias sao
    # dois valores diferentes, nenhuma das duas acha o registro, e o cenario nao
    # existe para ser medido. Mesma concessao do spec/config/schema_dump_spec.rb,
    # de sinal trocado. A suite local em SQLite pula este exemplo; o job `test`
    # da CI roda em MariaDB com a collation de producao, e e la que ele vale.
    if ActiveRecord::Base.connection.adapter_name == "Mysql2"
      it "detecta como duplicada a matricula que aparece em duas grafias" do
        inscricao  # a matricula do fixture e "M01"
        numero = inscricao.enrollment.enrollment_number

        post import_grades_xls_course_class_path(turma), params: {
          spreadsheet: pauta_de_linhas([
            linha(inscricao, nota: "8,7"),
            [1, numero.downcase, "aluno", "aluno@test.com", "1,0",
             ClassEnrollment::ATTENDANCE_TRUE, ClassEnrollment::REGISTERED,
             nil, "Nao", I18n.l(inscricao.created_at, format: :defaultdatetime)]
          ])
        }

        expect(response.body).to include(
          I18n.t("xls_content.course_class.import_grades_xls_results.status_duplicate")
        )
      end
    end
  end

  # O token amarra a confirmacao a previa que a tela mostrou. Duas abas na
  # mesma turma dividem a chave da sessao: sem ele, confirmar na aba antiga
  # aplicaria a planilha da aba nova, que ninguem conferiu ali.
  context "previa por aba e cancelamento" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
    end

    def token_da_previa
      Nokogiri::HTML(response.body).at_css("input[name=token]")["value"]
    end

    it "recusa a confirmacao da previa que outra aba substituiu" do
      enviar(inscricao, nota: "8,7")
      token_antigo = token_da_previa
      enviar(inscricao, nota: "5,0")

      post import_grades_xls_course_class_path(turma),
        params: { confirm: "1", token: token_antigo }

      expect(inscricao.reload.grade).to be_nil
      expect(flash[:error]).to eq(
        I18n.t("xls_content.course_class.import_grades_xls_stale_preview")
      )
    end

    it "grava a previa confirmada com o proprio token" do
      enviar(inscricao, nota: "8,7")

      post import_grades_xls_course_class_path(turma),
        params: { confirm: "1", token: token_da_previa }

      expect(inscricao.reload.grade).to eq(87)
    end

    # "Cancelar" tira a previa da sessao. Sem isso ela fica la ate alguem
    # confirmar aquela turma, ocupando a coluna `sessions.data`, que tem teto.
    it "descarta a previa ao cancelar" do
      enviar(inscricao, nota: "8,7")
      token = token_da_previa

      get import_grades_xls_course_class_path(turma, cancel: 1, token: token)
      post import_grades_xls_course_class_path(turma),
        params: { confirm: "1", token: token }

      expect(inscricao.reload.grade).to be_nil
    end
  end

  # Estes falham. Sao os defeitos que esta rodada de revisao confirmou por
  # reproducao, e ficam aqui como criterio de aceitacao do proximo conserto.
  # Cada um foi medido com controle: com a causa desligada, o exemplo passa.
  #
  # Os tres primeiros descrevem a regra de confirmacao decidida na issue: lanca
  # o que esta pronto, numa transacao so, e diz quantas linhas ficaram
  # pendentes. Nao citam o texto da mensagem, so os numeros que ela tem de
  # trazer.
  context "defeitos em aberto" do
    before(:each) do
      role = FactoryBot.create(:role_administrador)
      sign_in create_confirmed_user([role], "admin@ic.uff.br")
    end

    def outra_inscricao
      FactoryBot.create(
        :class_enrollment, course_class: turma,
        grade: nil, situation: ClassEnrollment::REGISTERED
      )
    end

    def mensagens
      flash.to_h.values.join(" ")
    end

    def pauta_de_abas(abas)
      pacote = Axlsx::Package.new
      abas.each do |nome, linhas|
        pacote.workbook.add_worksheet(name: nome) do |sheet|
          next if linhas.nil?
          sheet.add_row cabecalho
          linhas.each { |uma| sheet.add_row uma }
        end
      end
      arquivo_enviado(pacote.to_stream.read)
    end

    def arquivo_enviado(conteudo)
      tempfile = Tempfile.new(["pauta", ".xlsx"])
      tempfile.binmode
      tempfile.write(conteudo)
      tempfile.rewind
      Rack::Test::UploadedFile.new(tempfile.path, nil, false, original_filename: "pauta.xlsx")
    end

    # Hoje a confirmacao de previa com linha recusada nao grava nada, e
    # responde com t(".import_grades_xls_rejected_rows"), chave que nao existe
    # no locale -- o professor le "Translation missing". A regra decidida e
    # outra: as linhas prontas sao lancadas, as recusadas ficam pendentes, e a
    # mensagem diz quantas foram e quantas faltam. Aqui sao 3 e 2.
    it "lanca as linhas prontas e diz quantas ficaram pendentes" do
      prontas = [inscricao, outra_inscricao, outra_inscricao]
      recusadas = [outra_inscricao, outra_inscricao]
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_linhas(
          prontas.map { |uma| linha(uma, nota: "8,7") } +
          recusadas.map { |uma| linha(uma, nota: "99,0") }
        )
      }
      confirmar

      expect(prontas.map { |uma| uma.reload.grade }).to eq([87, 87, 87])
      expect(recusadas.map { |uma| uma.reload.grade }).to eq([nil, nil])
      expect(mensagens).to match(/\b3\b/).and match(/\b2\b/)
    end

    # Linha que nao traz nada a lancar -- nota em branco, o resto igual ao que
    # o sistema ja tem -- sai na previa como "Pronto" e entra na contagem: com
    # uma nota preenchida e duas em branco, a tela anuncia "3 nota(s)
    # importada(s)". Essas linhas sao alunos pendentes, nao lancados.
    it "nao conta como lancada a linha sem nada a lancar" do
      em_branco = [outra_inscricao, outra_inscricao]
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_linhas(
          [linha(inscricao, nota: "8,7")] +
          em_branco.map { |uma| linha(uma, nota: nil) }
        )
      }
      status = Nokogiri::HTML(response.body).css("tbody tr").map do |tr|
        tr.css("td")[1].text.strip
      end
      confirmar

      expect(status[1..]).not_to include(status[0])
      expect(inscricao.reload.grade).to eq(87)
      expect(mensagens).to match(/\b1\b/).and match(/\b2\b/)
    end

    # As linhas prontas vao numa transacao so: se uma delas falha ao gravar,
    # nenhuma e lancada, e a tela diz que nada foi lancado. Hoje cada linha
    # grava na propria transacao, e o professor le sucesso e erro juntos, com
    # metade da pauta gravada. A falha e simulada no momento de gravar,
    # depois da previa e da revalidacao, que e quando ela acontece de verdade.
    it "nao lanca nenhuma linha pronta quando uma delas falha ao gravar" do
      segunda = outra_inscricao
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_linhas([
          linha(inscricao, nota: "8,7"),
          linha(segunda, nota: "9,0")
        ])
      }
      allow_any_instance_of(ClassEnrollment).to receive(:create_or_update)
        .and_wrap_original do |original, *args, **kwargs, &block|
          next false if original.receiver.id == segunda.id
          original.call(*args, **kwargs, &block)
        end
      confirmar

      expect([inscricao.reload.grade, segunda.reload.grade]).to eq([nil, nil])
      expect(flash[:error]).to be_present
      expect(flash[:info]).to be_blank
    end

    # A importacao le a primeira aba, nao a "Pauta da Turma". O Excel poe a
    # copia de uma aba antes da original, e o professor que guardou a pauta
    # antiga assim tem a copia lida no lugar dela: a tela anuncia "1 nota(s)
    # importada(s)" e nada e gravado.
    it "le a aba Pauta da Turma mesmo quando ela nao e a primeira" do
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_abas(
          "Pauta da Turma (2)" => [linha(inscricao, nota: nil)],
          "Pauta da Turma" => [linha(inscricao, nota: "8,7")]
        )
      }
      confirmar

      expect(inscricao.reload.grade).to eq(87)
    end

    # Planilha cuja pauta esta vazia -- o professor apagou tudo antes de
    # colar -- responde com erro 500.
    it "avisa em vez de estourar quando a pauta esta vazia" do
      post import_grades_xls_course_class_path(turma), params: {
        spreadsheet: pauta_de_abas("Pauta da Turma" => nil)
      }

      expect(response).to redirect_to(import_grades_xls_course_class_path(turma))
      expect(flash[:error]).to be_present
    end

    # A conferencia de divergencia olha nota, situacao, frequencia e "nao
    # contabilizar no CR", mas nao a observacao. A planilha traz a obs que
    # estava no sistema quando foi exportada; se alguem a edita entre a previa
    # e a confirmacao, a confirmacao a regrava por cima, sem aviso.
    it "nao regrava por cima a observacao editada depois da previa" do
      inscricao.update_columns(obs: "Observacao exportada")
      enviar(inscricao, nota: "8,7", obs: "Observacao exportada")
      inscricao.update_columns(obs: "Observacao editada no sistema")
      confirmar

      expect(inscricao.reload.obs).to eq("Observacao editada no sistema")
      expect(flash[:warning]).to be_present
    end

    # A pauta exportada grava a matricula como numero quando ela so tem
    # digitos: "0123" vira 123 na planilha, e a importacao da mesma planilha,
    # sem mudanca nenhuma, nao acha o aluno.
    it "reconhece a matricula da pauta que o proprio sistema exportou" do
      inscricao.enrollment.update_columns(enrollment_number: "0123")
      get summary_xls_course_class_path(turma, format: :xlsx)
      exportada = response.body.dup

      post import_grades_xls_course_class_path(turma),
        params: { spreadsheet: arquivo_enviado(exportada) }

      expect(celulas_da_previa[0]).to eq("0123")
      expect(celulas_da_previa[1]).not_to eq(
        I18n.t("xls_content.course_class.import_grades_xls_results.status_not_found")
      )
    end

    # Os outros caminhos de lancamento -- a tela da turma, a da inscricao e a
    # da matricula -- avisam o professor da turma por e-mail quando nota,
    # situacao ou frequencia mudam. A importacao avisa aluno e orientador, mas
    # nao o professor.
    it "avisa o professor da turma das notas lancadas" do
      professor = FactoryBot.create(:professor, email: "professor@example.com")
      turma.update!(professor: professor)
      destinatarios = []
      allow(Notifier).to receive(:send_emails) do |notifications:|
        destinatarios.concat(notifications.map { |uma| uma[:to] })
      end

      enviar(inscricao, nota: "8,7")
      confirmar

      expect(destinatarios).to include("professor@example.com")
    end

    # Com frequencia "I", a importacao troca a nota da planilha pela
    # grade_of_disapproval_for_absence. Com a variavel vazia, a nota vira nil,
    # e a linha e recusada ("Nota deve ser menor que 6,0 para situacao
    # Reprovado"). A tela, no mesmo caso, so troca a nota quando a variavel
    # esta preenchida (class_enrollments.js).
    it "lanca a falta com a nota da planilha quando nao ha nota de reprovacao por falta" do
      CustomVariable.where(variable: "grade_of_disapproval_for_absence").delete_all
      enviar(inscricao, nota: "3,0", frequencia: ClassEnrollment::ATTENDANCE_FALSE)
      confirmar

      inscricao.reload
      expect(inscricao.grade).to eq(30)
      expect(inscricao.disapproved_by_absence).to eq(true)
      expect(inscricao.situation).to eq(ClassEnrollment::DISAPPROVED)
    end

    # A coluna "Obs." da previa passou a mostrar so os erros de validacao, e o
    # `final_obs` saiu da celula: a observacao que a planilha traz -- e que a
    # confirmacao grava -- nao aparece mais em lugar nenhum da previa.
    # Controle: com a celula da versao anterior, passa.
    it "mostra na previa a observacao que vai ser gravada" do
      enviar(inscricao, nota: "8,7", obs: "Observacao da planilha")

      expect(celulas_da_previa[6]).to include("Observacao da planilha")
    end

    # A view da previa imprime flash[:warning] num bloco proprio, e o layout
    # passou a imprimir todo o flash. O aviso de divergencia sai duas vezes,
    # uma acima da navegacao e outra dentro da previa. Controle: com o layout
    # anterior, sai uma vez.
    it "mostra o aviso de divergencia uma vez so" do
      enviar(inscricao, nota: "8,7")
      inscricao.update_columns(grade: 50)
      confirmar

      aviso = I18n.t(
        "xls_content.course_class.import_grades_xls_results.data_changed_warning"
      )
      expect(response.body.scan(aviso).size).to eq(1)
    end
  end
end
