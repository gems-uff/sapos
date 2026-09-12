# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Monta no banco de teste um processo seletivo inteiro a partir de
# spec/fixtures/admissions/workflows.json (#681): templates e campos, fases com
# condições, comitês, rankings e vínculos. O arquivo descreve três formas de
# processo, sem programa real por trás: um exemplar de cada tipo de campo, de
# cada modo de avaliação e de cada regra de ranking que o SAPOS oferece. O que
# se protege é a combinação funcionar junta, não a configuração de alguém.
#
# O JSON usa chaves simbólicas (field_type "select", mode "and", condition
# "ge", order "desc") que este carregador traduz para as constantes dos
# modelos, então a fixture não depende dos rótulos traduzidos. Os membros de
# comitê são usuários sintéticos, limitados por `members_cap`. Ids do arquivo
# são mapeados para os ids novos; condições e colunas referenciam campos pelo
# nome e não precisam disso.
#
# Uma condição pode citar um campo que nenhum template tem, como acontece em
# configuração real que acumula referências a templates antigos. Para o modelo
# aceitar a condição, o campo ganha um FormField de reserva num template à
# parte, e o nome fica em `missing_fields`; na avaliação o candidato não tem o
# campo, e a condição é falsa, como no banco real.
class AdmissionsWorkflowLoader
  Result = Struct.new(
    :process, :phases, :phase_links, :committee_users, :ranking_links, :templates,
    :missing_fields, :data, keyword_init: true
  )

  FIXTURE = Rails.root.join("spec", "fixtures", "admissions", "workflows.json")

  def self.constants_of(klass, keys)
    keys.index_with { |key| klass.const_get(key.upcase) }
  end

  FIELD_TYPES = constants_of(Admissions::FormField, %w[
    html string number select radio collection_checkbox single_checkbox student_field
    file text city group scholarity residency date code email
  ])
  SYNCS = { "name" => Admissions::FormField::SYNC_NAME, "email" => Admissions::FormField::SYNC_EMAIL,
            "telephone" => Admissions::FormField::SYNC_TELEPHONE }
  TEMPLATE_TYPES = constants_of(Admissions::FormTemplate, %w[
    admission_form recommendation_letter consolidation_form ranking
  ])
  MODES = constants_of(Admissions::FormCondition, %w[and or condition none])
  COMPARISONS = constants_of(Admissions::FormCondition, %w[
    contains starts_with ends_with equals ge le gt lt neq null not_null
  ])
  BEHAVIORS = constants_of(Admissions::RankingConfig, %w[
    ignore_condition exception_condition exception_on_machine exception_on_precondition
    ignore_ranking exception_ranking
  ])
  ORDERS = constants_of(Admissions::RankingColumn, %w[asc desc])
  TEMPLATE_ENGINES = { "liquid" => Admissions::FormField::LIQUID }

  def self.load(process_id:, members_cap: 3, simple_url: nil)
    new(process_id, members_cap, simple_url).load
  end

  def initialize(process_id, members_cap, simple_url)
    @data = JSON.parse(File.read(FIXTURE))
    @process_json = @data["admission_processes"].find { |p| p["id"] == process_id } or
      raise ArgumentError, "processo #{process_id} não está em workflows.json"
    @members_cap = members_cap
    @simple_url = simple_url || "workflow-#{process_id}"
    @templates = {}
    @committees = {}
    @committee_users = {}
    @machines = {}
    @ranking_configs = {}
    @missing_fields = []
    @user_sequence = 0
  end

  def load
    level = Level.find_by(name: @process_json["level"]) ||
      FactoryBot.create(:level, name: @process_json["level"])
    status = EnrollmentStatus.find_by(name: @process_json["enrollment_status"]) ||
      FactoryBot.create(:enrollment_status, name: @process_json["enrollment_status"])
    # Aberto agora: o candidato precisa conseguir se inscrever. O spec fecha o
    # edital quando chega a hora de consolidar fase não parcial.
    process = Admissions::AdmissionProcess.create!(
      name: @process_json["name"], simple_url: @simple_url,
      year: @process_json["year"], semester: @process_json["semester"],
      start_date: Date.today - 10.days, end_date: Date.today + 10.days, edit_date: nil,
      admission_date: @process_json["admission_date"],
      min_letters: @process_json["min_letters"], max_letters: @process_json["max_letters"],
      allow_multiple_applications: @process_json["allow_multiple_applications"],
      require_session: @process_json["require_session"], visible: @process_json["visible"],
      staff_can_edit: @process_json["staff_can_edit"], staff_can_undo: @process_json["staff_can_undo"],
      enrollment_number_field: @process_json["enrollment_number_field"],
      level: level, enrollment_status: status,
      form_template: template(@process_json["form_template_id"]),
      letter_template: @process_json["letter_template_id"] && template(@process_json["letter_template_id"])
    )

    phases = {}
    phase_links = []
    @data["admission_phases"].each do |phase_json|
      link = phase_json["process_links"].find { |l| l["admission_process_id"] == @process_json["id"] }
      next if link.nil?
      phase = build_phase(phase_json)
      phases[phase_json["id"]] = phase
      phase_links << FactoryBot.create(
        :admission_process_phase, admission_process: process, admission_phase: phase,
        order: link["order"], partial_consolidation: link["partial_consolidation"]
      )
      @data["admission_committees"].each do |committee_json|
        next unless committee_json["phase_ids"].include?(phase_json["id"])
        FactoryBot.create(
          :admission_phase_committee, admission_phase: phase, admission_committee: committee(committee_json)
        )
      end
    end

    ranking_links = []
    @data["ranking_configs"].sort_by { |r| r["id"] }.each do |ranking_json|
      link = ranking_json["process_links"].find { |l| l["admission_process_id"] == @process_json["id"] }
      next if link.nil?
      ranking_links << Admissions::AdmissionProcessRanking.create!(
        admission_process: process, ranking_config: ranking_config(ranking_json),
        admission_phase: phases[link["admission_phase_id"]], order: link["order"]
      )
    end

    Result.new(
      process: process, phases: phases, phase_links: phase_links.sort_by(&:order),
      committee_users: @committee_users, ranking_links: ranking_links.sort_by(&:order),
      templates: @templates, missing_fields: @missing_fields.uniq, data: @data
    )
  end

  private
    def template(old_id)
      @templates[old_id] ||= begin
        json = @data["form_templates"].find { |t| t["id"] == old_id } or
          raise ArgumentError, "template #{old_id} não está em workflows.json"
        template = FactoryBot.create(
          :form_template, name: json["name"], template_type: TEMPLATE_TYPES.fetch(json["template_type"])
        )
        json["fields"].sort_by { |f| [f["order"] || 0, f["id"]] }.each do |field|
          Admissions::FormField.create!(
            form_template: template, name: field["name"],
            field_type: FIELD_TYPES.fetch(field["field_type"]),
            order: field["order"], sync: field["sync"] && SYNCS.fetch(field["sync"]),
            description: field["description"],
            configuration: field["configuration"] && JSON.dump(translate_configuration(field["configuration"]))
          )
        end
        template
      end
    end

    # A configuração de campo de código ou de e-mail guarda uma condição e o
    # motor de template no mesmo vocabulário das constantes; traduz-se antes de
    # gravar.
    def translate_configuration(configuration)
      translated = configuration.dup
      translated["condition"] = condition_hash(configuration["condition"]) if configuration["condition"]
      if configuration["template_type"]
        translated["template_type"] = TEMPLATE_ENGINES.fetch(configuration["template_type"])
      end
      translated
    end

    def condition_hash(json)
      {
        "mode" => MODES.fetch(json["mode"]),
        "field" => json["field"],
        "condition" => json["condition"] && COMPARISONS.fetch(json["condition"]),
        "value" => json["value"],
        "form_conditions" => (json["form_conditions"] || []).map { |child| condition_hash(child) },
      }
    end

    def build_phase(json)
      Admissions::AdmissionPhase.create!(
        name: json["name"],
        can_edit_candidate: json["can_edit_candidate"], candidate_can_edit: json["candidate_can_edit"],
        candidate_can_see_member: json["candidate_can_see_member"],
        candidate_can_see_shared: json["candidate_can_see_shared"],
        candidate_can_see_consolidation: json["candidate_can_see_consolidation"],
        committee_can_see_other_individual: json["committee_can_see_other_individual"],
        member_form: json["member_form_id"] && template(json["member_form_id"]),
        shared_form: json["shared_form_id"] && template(json["shared_form_id"]),
        candidate_form: json["candidate_form_id"] && template(json["candidate_form_id"]),
        consolidation_form: json["consolidation_form_id"] && template(json["consolidation_form_id"]),
        approval_condition: condition(json["approval_condition"]),
        keep_in_phase_condition: condition(json["keep_in_phase_condition"])
      )
    end

    def committee(json)
      @committees[json["id"]] ||= begin
        committee = FactoryBot.create(
          :admission_committee, name: json["name"], form_condition: condition(json["form_condition"])
        )
        count = [json["members_count"].to_i, @members_cap].min
        @committee_users[json["id"]] = count.times.map do
          user = synthetic_professor
          FactoryBot.create(:admission_committee_member, admission_committee: committee, user: user)
          user
        end
        committee
      end
    end

    def synthetic_professor
      @user_sequence += 1
      role = Role.find_by(id: Role::ROLE_PROFESSOR) || FactoryBot.create(:role_professor)
      email = "workflow-#{@process_json["id"]}-membro-#{@user_sequence}@example.com"
      professor = FactoryBot.create(:professor, name: "Membro #{@user_sequence}", email: email)
      user = User.create!(
        roles: [role], email: email, name: "Membro #{@user_sequence}",
        password: "A1b2c3d4!", professor: professor
      )
      user.skip_confirmation!
      user.save!
      user
    end

    # Árvore de condição do JSON para FormCondition, sem gravar: quem grava é
    # a associação do dono (fase, comitê, ranking).
    def condition(json)
      return nil if json.nil?
      mode = MODES.fetch(json["mode"])
      ensure_field(json["field"]) if mode == Admissions::FormCondition::CONDITION
      node = Admissions::FormCondition.new(
        mode: mode, field: json["field"],
        condition: json["condition"] && COMPARISONS.fetch(json["condition"]), value: json["value"]
      )
      (json["form_conditions"] || []).each { |child| node.form_conditions << condition(child) }
      node
    end

    def ensure_field(name)
      return if name.blank?
      return if Admissions::FormField.field_name_exists?(name)
      @reserve_template ||= FactoryBot.create(:form_template, name: "Campos referenciados (reserva)")
      FactoryBot.create(:form_field, form_template: @reserve_template, name: name)
      @missing_fields << name
    end

    def machine(json)
      @machines[json["id"]] ||= FactoryBot.create(
        :ranking_machine, name: json["name"], form_condition: condition(json["form_condition"])
      )
    end

    def ranking_config(json)
      @ranking_configs[json["id"]] ||= begin
        config = Admissions::RankingConfig.new(
          name: json["name"],
          behavior_on_invalid_condition: BEHAVIORS.fetch(json["behavior_on_invalid_condition"]),
          behavior_on_invalid_ranking: BEHAVIORS.fetch(json["behavior_on_invalid_ranking"]),
          form_condition: condition(json["form_condition"])
        )
        json["ranking_columns"].each do |column|
          ensure_field(column["name"])
          config.ranking_columns.build(name: column["name"], order: ORDERS.fetch(column["order"]))
        end
        json["ranking_groups"].each do |group|
          config.ranking_groups.build(name: group["name"], vacancies: group["vacancies"])
        end
        json["ranking_processes"].each do |process|
          config.ranking_processes.build(
            ranking_machine: machine(process["ranking_machine"]), vacancies: process["vacancies"],
            group: process["group"], order: process["order"], step: process["step"]
          )
        end
        if config.ranking_columns.empty?
          # Há ranking gravado sem coluna de ordenação em banco real, estado que
          # o modelo de hoje recusaria. Reproduz-se o dado como está.
          config.create_form_template
          config.save!(validate: false)
        else
          config.save!
        end
        config
      end
    end
end
