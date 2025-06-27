# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

## Forms

# Admission Form
admission_form = Admissions::FormTemplate.new({
  name: "Formulário para candidatura ao mestrado",
  template_type: "Formulário"
})
admission_form_fields_configs = Admissions::FormTemplatesController.sispos_sucupira_student_fields_config
admission_form_fields_configs += [
  { name: "Informações Gerais",
    field_type: Admissions::FormField::GROUP },
  { name: "Candidato solicita bolsa de estudos?",
    description: "Consulte no site se você está apto a solicitar bolsa.",
    field_type: Admissions::FormField::SELECT,
    configuration: JSON.dump({
      "required": true,
      "values": [
        "Não",
        "Sim (ainda não sou aluno de mestrado do Programa e quero concorrer a uma bolsa)",
        "Sim (já sou aluno de mestrado do Programa e quero concorrer a uma bolsa)"
      ]
    }) },
  { name: "Linhas de pesquisa",
    description: "Marcar entre uma e três linhas de pesquisa de interesse.",
    field_type: Admissions::FormField::COLLECTION_CHECKBOX,
    configuration: JSON.dump({
      "minselection": "1",
      "maxselection": "3",
      "vertical_layout": true,
      "values": [
        "Algoritmos e Otimização",
        "Ciência de Dados",
        "Computação Científica",
        "Computação Visual",
        "Engenharia de Sistemas e Informação",
        "Inteligência Artificial",
        "Sistemas de Computação",
      ]
    }) },
  { name: "Justificativa",
    description: "Discorrer em até 300 palavras sobre os motivos para ingressar em um curso de pós-graduação, perspectivas profissionais, objetivos e planos de carreira após a conclusão da pós-graduação, linhas de pesquisa de interesse e outros assuntos correlatos. ",
    field_type: Admissions::FormField::TEXT,
    configuration: JSON.dump({
      "required": false,
      "rows": "20",
      "cols": "80"
    }) },
]
admission_form_fields_configs.each do |attributes|
  admission_form.fields.build(attributes)
end
admission_form.save!

# Staging Form
staging_form = Admissions::FormTemplate.new({
  name: "Formulário para homologação",
  template_type: "Formulário"
})
staging_form_fields_configs = [
  { name: "Optante negro ou indígena",
    field_type: Admissions::FormField::SINGLE_CHECKBOX },
  { name: "PcD",
    field_type: Admissions::FormField::SINGLE_CHECKBOX },
  { name: "Homologação",
    field_type: Admissions::FormField::RADIO,
    configuration: JSON.dump({
      "required": true,
      "values": [
        "Deferida",
        "Indeferida",
      ]
    }) },
  { name: "Razão de indeferimento",
    description: "Mensagem opcional, que será enviada por email no caso de indeferimento.",
    field_type: Admissions::FormField::TEXT,
  },
]
staging_form_fields_configs.each do |attributes|
  staging_form.fields.build(attributes)
end
staging_form.save!

# Staging Consolidate Form
staging_consolidate_form = Admissions::FormTemplate.new({
  name: "Consolidação da homologação",
  description: "Envia email para os candidatos",
  template_type: "Consolidação"
})
staging_consolidate_form_fields_configs = [
  { name: "Notificação de deferimento",
    field_type: Admissions::FormField::EMAIL,
    configuration: JSON.dump({
      "to": "{{ application.email }}",
      "subject": "Candidatura homologada",
      "body": "{{ application.name }}\n\nSua candidatura na pós-graduação do IC foi homologada. O resultado será divulgado no site no prazo informado no edital.",
      "condition": { "field": "Homologação", "condition": "=", "value": "Deferida", "mode": "Condição" },
      "template_type": "Liquid"
    })
  },
  { name: "Notificação de indeferimento",
    field_type: Admissions::FormField::EMAIL,
    configuration: JSON.dump({
      "to": "{{ application.email }}",
      "subject": "Candidatura não homologada",
      "body": "{{ application.name }}\n\nSua candidatura na pós-graduação do IC não foi homologada.\n\n{{ fields[\"Razão de indeferimento\"] }}",
      "condition": { "field": "Homologação", "condition": "=", "value": "Indeferida", "mode": "Condição" },
      "template_type": "Liquid"
    })
  },
]
staging_consolidate_form_fields_configs.each do |attributes|
  staging_consolidate_form.fields.build(attributes)
end
staging_consolidate_form.save!

# Evaluation Form
evaluation_form = Admissions::FormTemplate.new({
  name: "Formulário para avaliação de mestrado",
  template_type: "Formulário"
})
evaluation_form_fields_configs = [
  { name: "Nota da formação acadêmica",
    description: "Nota de 0 a 10",
    field_type: Admissions::FormField::NUMBER,
    configuration: JSON.dump({
      "required": true
    }),
  },
  { name: "Nota da experiência acadêmica e profissional",
    description: "Nota de 0 a 10",
    field_type: Admissions::FormField::NUMBER,
    configuration: JSON.dump({
      "required": true
    }),
  },
  { name: "Observação",
    description: "Campo opcional, onde pode ser registrada a razão das notas ou algum detalhe importante.",
    field_type: Admissions::FormField::TEXT,
  }
]
evaluation_form_fields_configs.each do |attributes|
  evaluation_form.fields.build(attributes)
end
evaluation_form.save!

# Evaluation Consolidation Form
evaluation_consolidate_form = Admissions::FormTemplate.new({
  name: "Consolidação da avaliação de mestrado",
  description: "Calcula a nota final considerando a regra do edital",
  template_type: "Consolidação"
})
evaluation_consolidate_form_fields_configs = [
  { name: "Média da formação acadêmica",
    field_type: Admissions::FormField::CODE,
    configuration: JSON.dump({
      "code": "{{- committees | avg: 'Nota da formação acadêmica' -}}",
      "condition": { "mode": "Nenhuma", "field": "","condition": "Contém", "value": "","form_conditions": [] },
      "template_type": "Liquid",
      "code_type": "number"
    })
  },
  { name: "Média da experiência acadêmica e profissional",
    field_type: Admissions::FormField::CODE,
    configuration: JSON.dump({
      "code": "{{- committees | avg: 'Nota da experiência acadêmica e profissional' -}}",
      "condition": { "mode": "Nenhuma", "field": "","condition": "Contém", "value": "","form_conditions": [] },
      "template_type": "Liquid",
      "code_type": "number"
    })
  },
  { name: "Nota final",
    field_type: Admissions::FormField::CODE,
    configuration: JSON.dump({
      "code": "{%- assign v1 = fields['Média da formação acadêmica'] | times: 7 -%}\n{%- assign v2 = fields['Média da experiência acadêmica e profissional'] | times: 3 -%}\n{{- v1 | plus: v2 | divided_by: 10.0 -}}",
      "condition": { "mode": "Nenhuma", "field": "","condition": "Contém", "value": "","form_conditions": [] },
      "template_type": "Liquid",
      "code_type": "number"
    })
  },
]
evaluation_consolidate_form_fields_configs.each do |attributes|
  evaluation_consolidate_form.fields.build(attributes)
end
evaluation_consolidate_form.save!

## Committees
staging_committee = Admissions::AdmissionCommittee.new({
  name: "Comitê de homologação",
})
staging_committee.members.build({ user: User.first })
staging_committee.save!

evaluation_committee = Admissions::AdmissionCommittee.new({
  name: "Comitê de avaliação de mestrado",
})
evaluation_committee.members.build({ user: User.first })
evaluation_committee.save!

## Phases
staging_phase = Admissions::AdmissionPhase.new({
  name: "Fase de homologação",
  member_form: nil,
  shared_form: staging_form,
  consolidation_form: staging_consolidate_form,
  candidate_form: nil,
  can_edit_candidate: true,
  candidate_can_edit: false,
  candidate_can_see_member: false,
  candidate_can_see_shared: false,
  candidate_can_see_consolidation: false,
  committee_can_see_other_individual: false,
})
staging_phase.approval_condition = Admissions::FormCondition.new({ mode: "Condição", field: "Homologação", condition: "=", value: "Deferida" })
staging_phase.admission_phase_committees.build({ admission_committee: staging_committee })
staging_phase.save!


evaluation_phase = Admissions::AdmissionPhase.create({
  name: "Fase de avaliação de mestrado",
  member_form: evaluation_form,
  shared_form: nil,
  consolidation_form: evaluation_consolidate_form,
  candidate_form: nil,
  can_edit_candidate: false,
  candidate_can_edit: false,
  candidate_can_see_member: false,
  candidate_can_see_shared: false,
  candidate_can_see_consolidation: false,
  committee_can_see_other_individual: true,
})
evaluation_phase.approval_condition = Admissions::FormCondition.new({ mode: "Condição", field: "Nota final", condition: ">=", value: "6" })
evaluation_phase.admission_phase_committees.build({ admission_committee: evaluation_committee })
evaluation_phase.save!

## Ranking machines 
general_condition = Admissions::FormCondition.new({
  mode: "E"
})
general_condition.form_conditions.build({mode: "Condição", field: "Homologação", condition: "=", value: "Deferida"})
general_condition.form_conditions.build({mode: "Condição", field: "Candidato solicita bolsa de estudos?", condition: "!=", value: "Sim (já sou aluno de mestrado do Programa e quero concorrer a uma bolsa)"})
general_selection =  Admissions::RankingMachine.create!({
  name: "Ampla concorrência",
  form_condition: general_condition
})


pcd_condition = Admissions::FormCondition.new({
  mode: "E"
})
pcd_condition.form_conditions.build({mode: "Condição", field: "Homologação", condition: "=", value: "Deferida"})
pcd_condition.form_conditions.build({mode: "Condição", field: "PcD", condition: "=", value: "1"})
pcd_condition.form_conditions.build({mode: "Condição", field: "Candidato solicita bolsa de estudos?", condition: "!=", value: "Sim (já sou aluno de mestrado do Programa e quero concorrer a uma bolsa)"})
pcd_selection =  Admissions::RankingMachine.create!({
  name: "PcD",
  form_condition: pcd_condition
})

race_condition = Admissions::FormCondition.new({
  mode: "E"
})
race_condition.form_conditions.build({mode: "Condição", field: "Homologação", condition: "=", value: "Deferida"})
race_condition.form_conditions.build({mode: "Condição", field: "Optante negro ou indígena", condition: "=", value: "1"})
race_condition.form_conditions.build({mode: "Condição", field: "Candidato solicita bolsa de estudos?", condition: "!=", value: "Sim (já sou aluno de mestrado do Programa e quero concorrer a uma bolsa)"})
race_selection =  Admissions::RankingMachine.create!({
  name: "Racial",
  form_condition: pcd_condition
})

scholarship_selection = Admissions::RankingMachine.create!({
  name: "Bolsa",
})

## Ranking configs
general_ranking = Admissions::RankingConfig.new({
  name: "Ranking de mestrado",
  behavior_on_invalid_condition: "Erro - apenas em seletores",
  behavior_on_invalid_ranking: "Erro",
  candidate_can_see: false,

})
general_ranking.form_condition = Admissions::FormCondition.new({mode: "Condição", field: "Nota final", condition: ">=", value: "6"})
general_ranking.ranking_columns.build({name: "Nota final", order: "DESC"})
general_ranking.ranking_columns.build({name: "Média da formação acadêmica", order: "DESC"})
general_ranking.ranking_groups.build({name: "Geral", vacancies: "50"})
general_ranking.ranking_groups.build({name: "PcD", vacancies: "1"})
general_ranking.ranking_processes.build({order: "1", vacancies: "40", group: "Geral", ranking_machine: general_selection, step: "1"})
general_ranking.ranking_processes.build({order: "2", vacancies: "10", group: "Geral", ranking_machine: race_selection, step: "1"})
general_ranking.ranking_processes.build({order: "3", vacancies: "1", group: "PcD", ranking_machine: pcd_selection, step: "1"})
general_ranking.save!


scholarship_condition = Admissions::FormCondition.new({
  mode: "E"
})
scholarship_condition.form_conditions.build({mode: "Condição", field: "Homologação", condition: "=", value: "Deferida"})
or_condition = scholarship_condition.form_conditions.build({mode: "Ou"})
or_condition.form_conditions.build({mode: "Condição", field: "Candidato solicita bolsa de estudos?", condition: "Contém", value: "Sim (já sou aluno de mestrado do Programa e quero concorrer a uma bolsa)"})
and_condition = or_condition.form_conditions.build({mode: "E"})
and_condition.form_conditions.build({mode: "Condição", field: "Posição/Ranking de mestrado", condition: "Não nulo"})
and_condition.form_conditions.build({mode: "Condição", field: "Candidato solicita bolsa de estudos?", condition: "=", value: "Sim (ainda não sou aluno de mestrado do Programa e quero concorrer a uma bolsa)"})

scholarship_ranking = Admissions::RankingConfig.new({
  name: "Ranking de bolsas de mestrado",
  behavior_on_invalid_condition: "Erro - apenas em seletores",
  behavior_on_invalid_ranking: "Erro",
  candidate_can_see: false,
  form_condition: scholarship_condition,
})
scholarship_ranking.ranking_columns.build({name: "Nota final", order: "DESC"})
scholarship_ranking.ranking_columns.build({name: "Média da formação acadêmica", order: "DESC"})
scholarship_ranking.ranking_processes.build({order: "1", vacancies: "", group: "", ranking_machine: scholarship_selection, step: "1"})
scholarship_ranking.save!


## Admission processes

admission_process = Admissions::AdmissionProcess.new({
  name: "Mestrado 2025/1",
  simple_url: "mestrado-2025-1",
  year: "2025",
  semester: "1",
  start_date: "2024-11-11",
  end_date: "2024-12-09",
  form_template: admission_form,
  letter_template: nil,
  min_letters: nil,
  max_letters: nil,
  allow_multiple_applications: false,
  require_session: true,
  visible: true,
  staff_can_edit: false,
  staff_can_undo: false,
  level: Level.find_by(name: "Mestrado"),
  enrollment_status: EnrollmentStatus.find_by(name: "Regular"),
  enrollment_number_field: I18n.t("active_scaffold.admissions/form_template.generate_fields.cpf"),
  admission_date: "2025-03-01",
})

admission_process.phases.build({admission_phase: staging_phase, start_date: "2024-12-10", end_date: "2024-12-16", partial_consolidation: true})
admission_process.phases.build({admission_phase: evaluation_phase, start_date: "2024-12-17", end_date: "2024-01-13", partial_consolidation: false})

admission_process.rankings.build({ranking_config: general_ranking, admission_phase: evaluation_phase})
admission_process.rankings.build({ranking_config: scholarship_ranking, admission_phase: evaluation_phase})
admission_process.save!