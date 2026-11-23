# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Tabela verdade da troca de turma na secretaria (#781). O aluno pediu a troca
# (remoção da turma atual e adição da nova); a secretaria leva as duas metades
# a qualquer par de status, por todo caminho que grava.
#
# Dimensões, todas combinadas:
# - partida: troca pedida (as duas Solicitadas) ou efetivada (as duas
#   Efetivadas);
# - ordem das linhas, que o formulário segue ao validar: remoção mais antiga
#   (a primeira troca, em que a remoção é a adição original convertida) ou
#   adição mais antiga (o aluno voltou à turma anterior);
# - alvo: cada par de status (Solicitada, Inválida, Efetivada) para remoção e
#   adição, menos o de partida. Válida não entra: o código não a distingue de
#   Solicitada;
# - caminho e momento: formulário numa gravação (com cada metade primeiro no
#   envio), ações da lista em duas gravações e formulário em duas gravações
#   (cada uma com cada metade primeiro). O lote só efetiva: entra com a troca
#   pedida, nas duas ordens da lista.
#
# O oráculo, em cada gravação:
# - Estado. Nunca a adição Efetivada com a remoção não Efetivada (duas
#   inscrições na disciplina). Aceita, cada metade fica no status pedido, e o
#   aluno fica inscrito na turma atual se a remoção não está Efetivada e na
#   nova se a adição está. Recusada, nada muda.
# - Recusa do que é permitido. O formulário valida as linhas na ordem em
#   que foram criadas e revalida as que não mudaram, então recusa três
#   gravações que as ações aceitam: efetivar as duas metades com a adição
#   mais antiga, desfazer as duas metades da troca efetivada numa gravação e
#   negar só a remoção com a adição Solicitada. As duas primeiras pedem para
#   gravar primeiro a metade que libera a inscrição.
# - Mensagem. A recusa diz por quê, uma vez cada motivo: a adição que se
#   efetiva pede a remoção antes (ou diz que o aluno ainda está na turma
#   atual); a remoção que se desfaz com a adição efetivada esbarra na
#   inscrição única da disciplina. No formulário, o aviso geral fica no alto
#   e o motivo, na linha.
# - E-mail. A recusa não manda nenhum. Aceita, o professor de cada turma em
#   que uma inscrição é criada ou apagada é avisado; o aluno recebe a
#   alteração do pedido pelo formulário, e pelas ações só quando a metade é
#   efetivada.
RSpec.describe "Troca de turma na secretaria: tabela verdade", type: :request do
  before(:each) do
    @level = FactoryBot.create(:level, name: "Mestrado")
    status = FactoryBot.create(:enrollment_status, name: "Regular", user: true)
    student = FactoryBot.create(:student, name: "Ana", email: "ana@example.com")
    @enrollment = FactoryBot.create(
      :enrollment, enrollment_number: "M01", student: student,
      level: @level, enrollment_status: status
    )
    @student_user = create_confirmed_user(
      [FactoryBot.create(:role_aluno)], "ana.tabela@ic.uff.br", "Ana",
      "A1b2c3d4!", student: student
    )
    @admin = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "adm.tabela@ic.uff.br", "Adm"
    )
    FactoryBot.create(
      :class_schedule, year: 2026, semester: 2,
      enrollment_start: 30.days.ago, enrollment_end: 20.days.ago,
      period_start: 10.days.ago, enrollment_insert: 3.days.from_now,
      enrollment_remove: 3.days.from_now
    )
    type = FactoryBot.create(
      :course_type, on_demand: true, allow_multiple_classes: false
    )
    @course = FactoryBot.create(:course, course_type: type)
    @p1 = FactoryBot.create(:professor, name: "Primeiro", email: "primeiro@example.com")
    @p2 = FactoryBot.create(:professor, name: "Segundo", email: "segundo@example.com")
    [@p1, @p2].each do |professor|
      FactoryBot.create(
        :advisement_authorization, professor: professor, level: @level,
        start_date: Date.current - 1.day, end_date: nil
      )
    end
    class_p1 = FactoryBot.create(
      :course_class, course: @course, professor: @p1, year: 2026, semester: 2
    )
    @pedido = FactoryBot.create(
      :enrollment_request, enrollment: @enrollment, year: 2026, semester: 2
    )
    FactoryBot.create(
      :class_enrollment_request, enrollment_request: @pedido,
      course_class: class_p1, action: ClassEnrollmentRequest::INSERT,
      status: ClassEnrollmentRequest::EFFECTED
    )
  end

  requested = ClassEnrollmentRequest::REQUESTED
  invalid = ClassEnrollmentRequest::INVALID
  effected = ClassEnrollmentRequest::EFFECTED

  def student_picks(professor)
    sign_in @student_user
    post "/enrollment/#{@enrollment.id}/enroll/2026-2", params: {
      enrollment_request: {
        course_class_ids: [""], message: "",
        course_ids: {
          @course.id.to_s => { selected: "1", professor: professor.id.to_s }
        }
      }
    }
    sign_out @student_user
  end

  def line(professor)
    @pedido.class_enrollment_requests.reload
      .find { |cer| cer.course_class.professor == professor }
  end

  def enrolled
    ClassEnrollment.where(enrollment: @enrollment)
      .map { |class_enrollment| class_enrollment.course_class.professor }
  end

  # Ação de status numa linha, como o ícone da lista. A visita à lista antes
  # consome o flash da ação anterior.
  def act(cer, status)
    get class_enrollment_requests_path
    helper = {
      ClassEnrollmentRequest::EFFECTED => :set_effected_class_enrollment_request_path,
      ClassEnrollmentRequest::REQUESTED => :set_requested_class_enrollment_request_path,
      ClassEnrollmentRequest::INVALID => :set_invalid_class_enrollment_request_path
    }.fetch(status)
    put send(helper, cer)
    Array(flash[:error])
  end

  # Gravação do formulário do pedido: todas as linhas vão no envio, na ordem
  # dada, como a tela as mostra agora; só as de `changes` mudam de status.
  def form_save(order, changes)
    rows = { "0" => "" }
    order.each(&:reload).each do |cer|
      rows[cer.id.to_s] = {
        id: cer.id.to_s, course_class: cer.course_class_id.to_s,
        class_enrollment: cer.class_enrollment_id.to_s,
        status: changes.fetch(cer, cer.status)
      }
    end
    put enrollment_request_path(@pedido), params: {
      record: { comment_message: "", class_enrollment_requests: rows }
    }
    return [] if response.redirect?

    Nokogiri::HTML(response.body)
      .css(".errorExplanation li, .association-record-errors li")
      .map { |li| li.text.squish }
  end

  # Lote: a lista ordenada pela ação (Adição antes de Remoção em ASC) e o
  # "efetivar" sobre ela.
  def batch_effect(sort_direction)
    get class_enrollment_requests_path,
      params: { sort: "action", sort_direction: sort_direction }
    post effect_class_enrollment_requests_path
    Array(flash[:error])
  end

  def request_message(key)
    ClassEnrollmentRequest.new.errors.full_message(
      :course_class,
      I18n.t(
        "activerecord.errors.models.class_enrollment_request.attributes." \
        "course_class.#{key}"
      )
    )
  end

  def multiple_message
    ClassEnrollment.new.errors.full_message(
      :course_class,
      I18n.t(
        "activerecord.errors.models.class_enrollment.attributes." \
        "course_class.multiple_class_enrollments_not_allowed"
      )
    )
  end

  def release_first_message
    I18n.t(
      "activerecord.errors.models.enrollment_request.attributes.base." \
      "release_first"
    )
  end

  def invalid_class_message
    I18n.t(
      "activerecord.errors.models.enrollment_request.attributes.base." \
      "invalid_class.one"
    )
  end

  # Monta a troca pedida, com a ordem das linhas pedida, e guarda em @from e
  # @to o professor da turma atual e o da nova.
  def requested_switch(order)
    @order = order
    student_picks(@p2)
    @from, @to = @p1, @p2
    return if order == :removal_older

    sign_in @admin
    act(line(@p1), ClassEnrollmentRequest::EFFECTED)
    act(line(@p2), ClassEnrollmentRequest::EFFECTED)
    sign_out @admin
    student_picks(@p1)
    @from, @to = @p2, @p1
  end

  # A mesma troca, efetivada pelo caminho de sempre: remoção, depois adição.
  def effected_switch(order)
    requested_switch(order)
    sign_in @admin
    act(line(@from), ClassEnrollmentRequest::EFFECTED)
    act(line(@to), ClassEnrollmentRequest::EFFECTED)
    sign_out @admin
  end

  def state
    { removal: line(@from).status, insertion: line(@to).status }
  end

  # O oráculo do cabeçalho.
  def acceptable?(target)
    target[:insertion] != ClassEnrollmentRequest::EFFECTED ||
      target[:removal] == ClassEnrollmentRequest::EFFECTED
  end

  def enrolled_in(target)
    professors = []
    professors << @from if target[:removal] != ClassEnrollmentRequest::EFFECTED
    professors << @to if target[:insertion] == ClassEnrollmentRequest::EFFECTED
    professors
  end

  def form?(path)
    path != :actions
  end

  # O que as ações aceitam e o formulário recusa (ver o cabeçalho).
  def form_refuses?(path, before, changes)
    return false unless form?(path)

    effected_switch = before.values.all?(ClassEnrollmentRequest::EFFECTED)
    effecting_both = changes.values.all?(ClassEnrollmentRequest::EFFECTED) &&
      changes.size == 2
    effecting_both && @order == :insertion_older ||
      effected_switch && changes.size == 2 ||
      changes == { removal: ClassEnrollmentRequest::INVALID } &&
        before.values.all?(ClassEnrollmentRequest::REQUESTED)
  end

  def releases_first?(before, changes)
    changes.size == 2 && (
      changes.values.all?(ClassEnrollmentRequest::EFFECTED) ||
      before.values.all?(ClassEnrollmentRequest::EFFECTED)
    )
  end

  # O motivo, na linha que o tem.
  def reason(before, target)
    return multiple_message if before[:insertion] == ClassEnrollmentRequest::EFFECTED
    return request_message(:already_enrolled) if
      target[:removal] != ClassEnrollmentRequest::REQUESTED
    request_message(:remove_first)
  end

  def refusal(path, before, target, changes)
    return [reason(before, target)] unless form?(path)

    messages = [invalid_class_message, reason(before, target)]
    messages.unshift(release_first_message) if releases_first?(before, changes)
    messages
  end

  # Destinatários: o professor de cada turma em que a inscrição muda e o
  # aluno, conforme o caminho.
  def recipients(path, before, target, changes)
    was = enrolled_in(before)
    now = enrolled_in(target)
    professors = ((was - now) + (now - was)).map(&:email)
    student = form?(path) || changes.values.first == ClassEnrollmentRequest::EFFECTED
    (student ? ["ana@example.com"] : []) + professors
  end

  def delivered_to
    ActionMailer::Base.deliveries.flat_map(&:to)
  end

  def expect_state(expected)
    expect(state).to eq(expected)
    expect(enrolled).to eq(enrolled_in(expected))
  end

  # Uma gravação pelo caminho dado, conferida contra o oráculo.
  def save_and_check(path, changes)
    before = state
    target = before.merge(changes)
    lines = { removal: line(@from), insertion: line(@to) }
    ActionMailer::Base.deliveries.clear
    errors =
      case path
      when :actions
        half, status = changes.first
        act(lines[half], status)
      else
        order = [lines[:removal], lines[:insertion]]
        order.reverse! if path == :form_insertion_first
        form_save(order, changes.transform_keys { |half| lines[half] })
      end

    if acceptable?(target) && !form_refuses?(path, before, changes)
      expect(errors).to eq([])
      expect_state(target)
      expect(delivered_to).to match_array(recipients(path, before, target, changes))
    else
      expect(errors).to match_array(refusal(path, before, target, changes))
      expect_state(before)
      expect(delivered_to).to eq([])
    end
  end

  starts = {
    "troca pedida" => [:requested_switch, { removal: requested, insertion: requested }],
    "troca efetivada" => [:effected_switch, { removal: effected, insertion: effected }]
  }
  orders = {
    removal_older: "remoção mais antiga (primeira troca)",
    insertion_older: "adição mais antiga (volta à turma anterior)"
  }
  one_save = {
    "formulário, 1 gravação, remoção primeiro no envio" => :form_removal_first,
    "formulário, 1 gravação, adição primeiro no envio" => :form_insertion_first
  }
  two_saves = {
    "ações, 2 gravações" => :actions,
    "formulário, 2 gravações" => :form_removal_first
  }
  halves = { removal: "remoção", insertion: "adição" }
  statuses = [requested, invalid, effected]

  starts.each do |start_label, (setup, start)|
    context "com a #{start_label}" do
      orders.each do |order, order_label|
        context "e a #{order_label}" do
          before(:each) do
            send(setup, order)
            sign_in @admin
            expect_state(start)
          end

          statuses.product(statuses).each do |removal, insertion|
            target = { removal: removal, insertion: insertion }
            next if target == start

            changes = target.reject { |half, status| start[half] == status }
            context "levando a remoção a #{removal} e a adição a #{insertion}" do
              one_save.each do |path_label, path|
                it path_label do
                  save_and_check(path, changes)
                end
              end

              two_saves.each do |path_label, path|
                [%i[removal insertion], %i[insertion removal]].each do |sequence|
                  it "#{path_label}, #{halves[sequence.first]} primeiro" do
                    sequence.each do |half|
                      next unless changes.key?(half)

                      save_and_check(path, half => changes[half])
                    end
                  end
                end
              end
            end
          end

          next unless setup == :requested_switch

          { "ASC" => "adição", "DESC" => "remoção" }.each do |direction, first|
            it "lote, #{first} primeiro na lista: troca" do
              ActionMailer::Base.deliveries.clear

              expect(batch_effect(direction)).to eq([])
              expect_state(removal: effected, insertion: effected)
              expect(delivered_to).to match_array(
                ["ana@example.com", @from.email, @to.email]
              )
            end
          end
        end
      end
    end
  end
end
