# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Golden-master das permissões — issue #742.
#
# O spec/models/ability_spec.rb verifica `can?` em amostras escolhidas, e não
# verifica `accessible_by`, que é o que o active_scaffold aplica à listagem de
# todo scaffold (beginning_of_chain) e às associações. Este arquivo completa
# aquele: em vez de amostras, a matriz inteira — cada papel × cada modelo ×
# cada ação, sobre a classe, sobre cada registro rotulado e pelo
# `accessible_by` — comparada com o baseline spec/goldens/ability_matrix.txt.
#
# Não afirma que as permissões estão CERTAS; afirma que continuam IGUAIS. É a
# guarda para upgrade do cancancan e do active_scaffold, e para mudança no
# Ability: toda diferença no baseline precisa de explicação antes do
# GOLDEN=overwrite.
#
# O conjunto de dados existe para atravessar cada ramo de condição do Ability:
# professor dono e não dono, artigo sem dono, orientando e não orientando,
# pedido de inscrição efetivado, solicitado e com status nulo (#909), turma do
# semestre corrente e de outro, as três configurações de lançamento de nota,
# candidatura com pendência do usuário, de outro e sem pendência, aluno com e
# sem matrícula aprovada, usuário com dois papéis.
#
# ABILITY_MATRIX_SQL=<arquivo> grava também o SQL de cada accessible_by, para
# diagnosticar uma diferença; não entra no baseline. ABILITY_MATRIX_OUT=<arquivo>
# grava a matriz renderizada, para comparar duas versões noutro banco: em
# MariaDB a mensagem de erro do adaptador difere da do SQLite, e o que se
# compara lá é uma versão do cancancan contra a outra, não contra o baseline.
RSpec.describe "Matriz de permissões", type: :model do
  include GoldenMaster
  include ActiveSupport::Testing::TimeHelpers

  before(:each) { travel_to GoldenMaster::FROZEN_AT }
  after(:each) { travel_back }

  def label(record, name)
    @labels[record] = name
    record
  end

  def user_with(roles, name, actual_role: nil, **links)
    user = create_confirmed_user(roles, "#{name}@matriz.test", name, "A1b2c3d4!", **links)
    user.update_column(:actual_role, actual_role) if actual_role
    user.reload
  end

  # Papel professor sem professor, ou aluno sem aluno: a validação do User
  # recusa, mas o Ability trata o caso, e dado antigo ou script chega lá.
  def user_without_link(role, name)
    user = User.new(email: "#{name}@matriz.test", name: name, password: "A1b2c3d4!")
    user.skip_confirmation!
    user.save!(validate: false)
    UserRole.create!(user: user, role: role)
    user.update_column(:actual_role, role.id)
    user.reload
  end

  # A orientação exige a autorização do professor no nível da matrícula; os
  # reloads seguem o motivo descrito em spec/models/ability_spec.rb.
  def advise(enrollment, professor)
    FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)
    professor.advisement_authorizations.reload
    FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
    enrollment.reload
  end

  def post_grades(value)
    CustomVariable.where(variable: "professor_login_can_post_grades").delete_all
    return if value.nil?

    CustomVariable.create!(variable: "professor_login_can_post_grades", value: value)
  end

  before(:each) do
    @labels = {}
    roles = {
      administrador: FactoryBot.create(:role_administrador),
      coordenacao: FactoryBot.create(:role_coordenacao),
      secretaria: FactoryBot.create(:role_secretaria),
      professor: FactoryBot.create(:role_professor),
      aluno: FactoryBot.create(:role_aluno),
      suporte: FactoryBot.create(:role_suporte),
      desconhecido: FactoryBot.create(:role_desconhecido),
    }

    # Professores e alunos vêm antes dos usuários: a validação do User exige
    # o vínculo para os papéis professor e aluno.
    @prof_a = label(FactoryBot.create(:professor), "prof_a")
    @prof_b = label(FactoryBot.create(:professor), "prof_b")
    @prof_c = label(FactoryBot.create(:professor), "prof_c")
    @st_a = label(FactoryBot.create(:student), "st_a")
    @st_b = label(FactoryBot.create(:student), "st_b")

    # Usuários. Todos persistidos: as regras de admissão comparam user.id, e um
    # usuário sem id casaria com as pendências sem usuário.
    @users = {
      administrador: user_with([roles[:administrador]], "administrador"),
      coordenacao: user_with([roles[:coordenacao]], "coordenacao"),
      secretaria: user_with([roles[:secretaria]], "secretaria"),
      suporte: user_with([roles[:suporte]], "suporte"),
      desconhecido: user_with([roles[:desconhecido]], "desconhecido"),
      professor: user_with([roles[:professor]], "professor", professor: @prof_a),
      professor_sem_vinculo: user_without_link(roles[:professor], "professor_sem_vinculo"),
      professor_coordenador: user_with(
        [roles[:professor], roles[:coordenacao]], "professor_coordenador",
        actual_role: Role::ROLE_COORDENACAO, professor: @prof_c
      ),
      aluno: user_with([roles[:aluno]], "aluno", student: @st_a),
      aluno_sem_vinculo: user_without_link(roles[:aluno], "aluno_sem_vinculo"),
    }
    [@prof_a, @prof_c, @st_a].each(&:reload)

    # Alunos e matrículas: aprovada, aberta e reprovada; status que permite e
    # que proíbe o professor de gerar o boletim.
    es_permite = label(
      FactoryBot.create(:enrollment_status, professor_can_generate_report: true), "es_permite"
    )
    es_proibe = label(
      FactoryBot.create(:enrollment_status, professor_can_generate_report: false), "es_proibe"
    )
    dr_aprovado = label(
      FactoryBot.create(:dismissal_reason, thesis_judgement: DismissalReason::APPROVED), "dr_aprovado"
    )
    dr_reprovado = label(
      FactoryBot.create(:dismissal_reason, thesis_judgement: DismissalReason::REPROVED), "dr_reprovado"
    )
    level = label(FactoryBot.create(:level), "level")

    @enr_a_aprovada = label(
      FactoryBot.create(:enrollment, student: @st_a, level: level, enrollment_status: es_permite),
      "enr_a_aprovada"
    )
    @enr_a_aberta = label(
      FactoryBot.create(:enrollment, student: @st_a, level: level, enrollment_status: es_proibe),
      "enr_a_aberta"
    )
    @enr_b_reprovada = label(
      FactoryBot.create(:enrollment, student: @st_b, level: level, enrollment_status: es_permite),
      "enr_b_reprovada"
    )
    @enr_b_aprovada = label(
      FactoryBot.create(:enrollment, student: @st_b, level: level, enrollment_status: es_proibe),
      "enr_b_aprovada"
    )
    label(FactoryBot.create(:dismissal, enrollment: @enr_a_aprovada, dismissal_reason: dr_aprovado), "dis_a_aprovada")
    label(FactoryBot.create(:dismissal, enrollment: @enr_b_reprovada, dismissal_reason: dr_reprovado), "dis_b_reprovada")
    label(FactoryBot.create(:dismissal, enrollment: @enr_b_aprovada, dismissal_reason: dr_aprovado), "dis_b_aprovada")
    [@enr_a_aprovada, @enr_a_aberta, @enr_b_reprovada, @enr_b_aprovada].each(&:reload)

    advise(@enr_a_aprovada, @prof_a)
    advise(@enr_b_reprovada, @prof_b)
    @prof_a.advisements.each { |advisement| label(advisement, "adv_a") }
    @prof_b.advisements.each { |advisement| label(advisement, "adv_b") }

    # Turmas: do professor no semestre corrente, dele em semestre passado, e de
    # outro professor no semestre corrente.
    current = YearSemester.current
    cc_a_atual = label(
      FactoryBot.create(:course_class, professor: @prof_a, year: current.year, semester: current.semester),
      "cc_a_atual"
    )
    cc_a_antiga = label(
      FactoryBot.create(:course_class, professor: @prof_a, year: current.year - 1, semester: 2),
      "cc_a_antiga"
    )
    cc_b_atual = label(
      FactoryBot.create(:course_class, professor: @prof_b, year: current.year, semester: current.semester),
      "cc_b_atual"
    )
    label(FactoryBot.create(:class_enrollment, course_class: cc_a_atual, enrollment: @enr_a_aprovada), "ce_a_atual")
    ce_a_antiga = label(FactoryBot.create(:class_enrollment, course_class: cc_a_antiga, enrollment: @enr_a_aprovada), "ce_a_antiga")
    label(FactoryBot.create(:class_enrollment, course_class: cc_b_atual, enrollment: @enr_b_reprovada), "ce_b_atual")

    # Pedidos de inscrição: do orientando e de um não orientando; itens
    # solicitado, efetivado e com status nulo. O nulo não passa pela validação,
    # mas a coluna o aceita, e é exatamente a coluna do `cannot` com condição.
    er_a = label(
      FactoryBot.create(:enrollment_request, enrollment: @enr_a_aprovada, year: current.year, semester: current.semester),
      "er_a"
    )
    er_b = label(
      FactoryBot.create(:enrollment_request, enrollment: @enr_b_reprovada, year: current.year, semester: current.semester),
      "er_b"
    )
    label(
      FactoryBot.create(:class_enrollment_request, enrollment_request: er_a, course_class: cc_a_atual),
      "cer_a_solicitada"
    )
    label(
      FactoryBot.create(
        :class_enrollment_request, enrollment_request: er_a, course_class: cc_a_antiga,
        status: ClassEnrollmentRequest::EFFECTED, class_enrollment: ce_a_antiga
      ),
      "cer_a_efetivada"
    )
    cer_a_nula = label(
      FactoryBot.create(:class_enrollment_request, enrollment_request: er_a, course_class: cc_b_atual),
      "cer_a_status_nulo"
    )
    cer_a_nula.update_column(:status, nil)
    label(
      FactoryBot.create(:class_enrollment_request, enrollment_request: er_b, course_class: cc_b_atual),
      "cer_b_solicitada"
    )

    # Projetos e artigos: do professor e alheios; linhas de autoria de cada um
    # e de um artigo ainda não salvo, como o subformulário as monta.
    label(FactoryBot.create(:grant, professor: @prof_a), "grant_a")
    label(FactoryBot.create(:grant, professor: @prof_b), "grant_b")
    label(FactoryBot.create(:grant, professor: @prof_c), "grant_c")
    paper_a = label(FactoryBot.create(:paper, owner: @prof_a), "paper_a")
    paper_b = label(FactoryBot.create(:paper, owner: @prof_b), "paper_b")
    label(FactoryBot.create(:paper_professor, paper: paper_a, professor: @prof_b), "pp_a")
    label(FactoryBot.create(:paper_professor, paper: paper_b, professor: @prof_a), "pp_b")
    label(FactoryBot.create(:paper_student, paper: paper_a, student: @st_a), "ps_a")
    label(FactoryBot.create(:paper_student, paper: paper_b, student: @st_b), "ps_b")
    label(PaperProfessor.new(paper: Paper.new, professor: @prof_a), "pp_novo_sem_dono")
    label(PaperStudent.new(paper: Paper.new, student: @st_a), "ps_novo_sem_dono")

    # Declarações: em memória, como no ability_spec — persistir exige uma
    # consulta válida, que não é o que se mede aqui. O argumento extra é o
    # número de matrícula, como o controller passa.
    as_aberta = label(Assertion.new(name: "as_aberta", student_can_generate: true), "as_aberta")
    as_fechada = label(Assertion.new(name: "as_fechada", student_can_generate: false), "as_fechada")
    numbers = [@enr_a_aprovada.enrollment_number, @enr_b_aprovada.enrollment_number]
    @labels[numbers[0]] = "num_enr_a"
    @labels[numbers[1]] = "num_enr_b"
    @extra_args = [as_aberta, as_fechada].index_with([[], [numbers[0]], [numbers[1]]])

    # Processo seletivo: candidatura com pendência do professor, com pendência
    # de outro usuário, com pendência compartilhada (sem usuário) e sem
    # pendência; carta, avaliação, resultado de fase e de ranking sobre elas,
    # cada um com o formulário preenchido que as regras de FilledForm alcançam.
    process = label(FactoryBot.create(:admission_process, :with_letter_template), "processo")
    phase = label(FactoryBot.create(:admission_phase, :with_member_form), "fase")
    ranking = label(FactoryBot.create(:ranking_config), "ranking")
    apps = %w[app_pendente app_outro app_compartilhada app_sem].to_h do |name|
      app = FactoryBot.create(:admission_application, admission_process: process, name: name, email: "#{name}@matriz.test")
      label(app.filled_form, "ff_#{name}")
      [name, label(app, name)]
    end
    label(
      FactoryBot.create(:admission_pendency, admission_application: apps["app_pendente"], admission_phase: phase, user: @users[:professor]),
      "pend_professor"
    )
    label(
      FactoryBot.create(:admission_pendency, admission_application: apps["app_outro"], admission_phase: phase, user: @users[:professor_coordenador]),
      "pend_outro"
    )
    label(
      FactoryBot.create(:admission_pendency, admission_application: apps["app_compartilhada"], admission_phase: phase, user: nil),
      "pend_compartilhada"
    )
    %w[app_pendente app_sem].each do |name|
      letter = label(FactoryBot.create(:letter_request, admission_application: apps[name]), "carta_#{name}")
      label(letter.filled_form, "ff_carta_#{name}")
      result = label(
        FactoryBot.create(:admission_phase_result, admission_application: apps[name], admission_phase: phase),
        "resultado_#{name}"
      )
      label(result.filled_form, "ff_resultado_#{name}")
      rank = label(
        FactoryBot.create(:admission_ranking_result, admission_application: apps[name], ranking_config: ranking),
        "ranking_#{name}"
      )
      label(rank.filled_form, "ff_ranking_#{name}")
    end
    { "professor" => @users[:professor], "outro" => @users[:professor_coordenador] }.each do |who, user|
      evaluation = label(
        FactoryBot.create(:admission_phase_evaluation, admission_application: apps["app_sem"], admission_phase: phase, user: user),
        "avaliacao_#{who}"
      )
      label(evaluation.filled_form, "ff_avaliacao_#{who}")
    end
    label(
      FactoryBot.create(:filled_form_field, filled_form: apps["app_pendente"].filled_form),
      "campo_app_pendente"
    )
  end

  def users_for_matrix
    u = @users
    as_professor = User.find(u[:professor_coordenador].id).tap { |user| user.actual_role = Role::ROLE_PROFESSOR }
    {
      "visitante" => -> { Ability.new(nil) },
      "desconhecido" => -> { Ability.new(u[:desconhecido]) },
      "administrador" => -> { Ability.new(u[:administrador]) },
      "coordenacao" => -> { Ability.new(u[:coordenacao]) },
      "secretaria" => -> { Ability.new(u[:secretaria]) },
      "suporte" => -> { Ability.new(u[:suporte]) },
      "professor (sem lançamento de nota)" => -> { post_grades(nil) || Ability.new(u[:professor]) },
      "professor (nota no semestre corrente)" => -> { post_grades("yes") && Ability.new(u[:professor]) },
      "professor (nota em todo semestre)" => -> { post_grades("yes_all_semesters") && Ability.new(u[:professor]) },
      "professor sem professor vinculado" => -> { post_grades(nil) || Ability.new(u[:professor_sem_vinculo]) },
      "professor e coordenador, atuando como coordenação" => -> { Ability.new(u[:professor_coordenador]) },
      "professor e coordenador, atuando como professor" => -> { Ability.new(as_professor) },
      "aluno" => -> { Ability.new(u[:aluno]) },
      "aluno sem aluno vinculado" => -> { Ability.new(u[:aluno_sem_vinculo]) },
    }
  end

  it "mantém o baseline" do
    sql_path = ENV["ABILITY_MATRIX_SQL"]
    sql = sql_path ? +"" : nil
    matrix = AbilityMatrix.new(
      users: users_for_matrix, labels: @labels, extra_args: @extra_args, sql_dump: sql
    ).render
    File.write(sql_path, sql) if sql_path
    File.write(ENV["ABILITY_MATRIX_OUT"], matrix) if ENV["ABILITY_MATRIX_OUT"]

    expect_matches_golden("ability_matrix", matrix, format: :text)
  end
end
