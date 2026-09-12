# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Montagem de cenários do processo seletivo para os specs de consolidação,
# ranking, relatório e formulário (#681).
#
# O domínio pede muitos registros para um caso mínimo: template com campos,
# processo apontando para o template, candidatura com formulário preenchido e
# valor por campo, fase ligada ao processo por AdmissionProcessPhase, condição
# de aprovação sobre um campo que precisa existir. Estes helpers montam isso
# por nome de campo e valor, para que cada exemplo descreva só o que o
# distingue dos outros.
module AdmissionsScenarioHelpers
  # Template de inscrição com os campos dados: { "nota" => NUMBER, ... }.
  # O valor pode ser o tipo (String) ou um Hash com :field_type e demais
  # atributos do FormField (configuration, sync, order).
  def create_admission_template(name, fields, template_type: Admissions::FormTemplate::ADMISSION_FORM)
    template = FactoryBot.create(:form_template, name: name, template_type: template_type)
    fields.each_with_index do |(field_name, spec), index|
      attrs = spec.is_a?(Hash) ? spec.dup : { field_type: spec }
      attrs[:configuration] = JSON.dump(attrs[:configuration]) if attrs[:configuration].is_a?(Hash)
      FactoryBot.create(
        :form_field,
        { form_template: template, name: field_name, order: index + 1 }.merge(attrs)
      )
    end
    template
  end

  # Template de consolidação: só aceita campos de código e de e-mail.
  def create_consolidation_template(name, fields)
    create_admission_template(
      name, fields, template_type: Admissions::FormTemplate::CONSOLIDATION_FORM
    )
  end

  # Campo de código Liquid, na forma que o template de consolidação exige.
  def code_field(code, code_type: "number", condition: nil)
    configuration = {
      "code" => code,
      "template_type" => Admissions::FormField::LIQUID,
      "code_type" => code_type,
    }
    configuration["condition"] = condition if condition
    { field_type: Admissions::FormField::CODE, configuration: configuration }
  end

  # Processo fechado para inscrição (terminou há dez dias), com URL própria
  # para não colidir com a de outro spec no mesmo banco.
  def create_closed_admission_process(template, simple_url:, **attrs)
    FactoryBot.create(
      :admission_process, {
        form_template: template,
        simple_url: simple_url,
        name: "Processo #{simple_url}",
        start_date: Date.today - 40.days,
        end_date: Date.today - 10.days,
        edit_date: Date.today - 5.days,
      }.merge(attrs)
    )
  end

  # Candidatura com formulário preenchido e um valor por nome de campo.
  def create_application(process, name: "Ana", email: nil, filled: true, fields: {}, **attrs)
    email ||= "#{name.parameterize}-#{SecureRandom.hex(3)}@example.com"
    filled_form = FactoryBot.create(
      :filled_form, form_template: process.form_template, is_filled: filled
    )
    application = FactoryBot.create(
      :admission_application, {
        admission_process: process, name: name, email: email, filled_form: filled_form
      }.merge(attrs)
    )
    fill_fields(filled_form, fields)
    application
  end

  # Grava um valor por campo num formulário preenchido, achando o FormField pelo
  # nome dentro do template do formulário. Valor Array vira lista; Hash com
  # :file anexa arquivo.
  def fill_fields(filled_form, fields)
    fields.each do |field_name, value|
      form_field = filled_form.form_template.fields.find_by!(name: field_name)
      attrs = { filled_form: filled_form, form_field: form_field, value: nil }
      case value
      when Array then attrs[:list] = value
      when Hash then attrs.merge!(value)
      else attrs[:value] = value
      end
      FactoryBot.create(:filled_form_field, **attrs)
    end
  end

  # Condição simples "campo <op> valor". O campo precisa existir em algum
  # template, senão o FormCondition recusa.
  def field_condition(field, condition, value = nil)
    Admissions::FormCondition.new(
      mode: Admissions::FormCondition::CONDITION,
      field: field, condition: condition, value: value
    )
  end

  # Condição composta (AND/OR) sobre subcondições.
  def composed_condition(mode, *children)
    condition = Admissions::FormCondition.new(mode: mode)
    children.each { |child| condition.form_conditions << child }
    condition
  end

  # Fase ligada ao processo na ordem dada.
  def add_phase(process, order, name: "Fase #{order}", partial_consolidation: true, **attrs)
    phase = FactoryBot.create(:admission_phase, { name: name }.merge(attrs))
    FactoryBot.create(
      :admission_process_phase,
      admission_process: process, admission_phase: phase,
      order: order, partial_consolidation: partial_consolidation
    )
    phase
  end

  # Comitê com os usuários dados, ligado à fase, com condição opcional.
  def add_committee(phase, users, name: "Comitê", form_condition: nil)
    committee = FactoryBot.create(
      :admission_committee, name: name, form_condition: form_condition
    )
    users.each do |user|
      FactoryBot.create(:admission_committee_member, admission_committee: committee, user: user)
    end
    FactoryBot.create(
      :admission_phase_committee, admission_phase: phase, admission_committee: committee
    )
    committee
  end

  # Avaliação individual de um membro do comitê, já preenchida.
  def create_evaluation(application, phase, user, fields: {})
    evaluation = Admissions::AdmissionPhaseEvaluation.create!(
      admission_phase: phase, admission_application: application, user: user
    )
    evaluation.filled_form.update!(is_filled: true)
    fill_fields(evaluation.filled_form, fields)
    evaluation
  end

  # Resultado de fase (compartilhado, de candidato ou de consolidação). O
  # template vem da fase, conforme o modo; quando a fase não tem o formulário
  # daquele modo, passe um em `template`.
  def create_phase_result(application, phase, mode, filled: true, fields: {}, template: nil)
    result = Admissions::AdmissionPhaseResult.new(
      admission_phase: phase, admission_application: application, mode: mode
    )
    result.filled_form.form_template ||= template
    result.save!
    result.filled_form.update!(is_filled: filled)
    fill_fields(result.filled_form, fields)
    result
  end

  # Usuário com papel Professor. O User exige um Professor associado quando o
  # papel é esse, então o registro de Professor vem junto.
  def professor_user(email)
    role = Role.find_by(id: Role::ROLE_PROFESSOR) || FactoryBot.create(:role_professor)
    name = email.split("@").first
    professor = FactoryBot.create(:professor, name: name, email: email)
    create_confirmed_user([role], email, name, professor: professor)
  end
end

RSpec.configure do |config|
  config.include AdmissionsScenarioHelpers, type: :model
  config.include AdmissionsScenarioHelpers, type: :request
end
