# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

CustomVariable.create([
  { description: "Pontos para orientador único", variable: "single_advisor_points", value: "1.0" },
  { description: "Pontos para orientador múltiplo", variable: "multiple_advisor_points", value: "0.5" },

  { description: "País padrão de emissão da identidade", variable: "identity_issuing_country", value: "Brasil" },
  { description: "Texto no final do quadro de horários", variable: "class_schedule_text", value: "Alunos interessados em cursar disciplinas de Tópicos Avançados devem consultar os respectivos professores antes da matrícula." },
  { description: "E-mail de redirecionamento para as notificações", variable: "redirect_email", value: "" },
  { description: "E-mail das resposta de emails automáticos", variable: "reply_to", value: "sapos@sapos.ic.uff.br" },
  { description: "Texto de rodapé da notificação",
    variable: "notification_footer",
    value: <<~TEXT
      Pós-Graduação em Computação - IC/UFF
      Este e-mail foi enviado automaticamente pelo SAPOS. Por favor, não responda.
      Em caso de dúvida, procure a secretaria.
    TEXT
  },
  { description: "Nota mínima para aprovação", variable: "minimum_grade_for_approval", value: "6.0" },
  { description: "Nota de reprovação por falta", variable: "grade_of_disapproval_for_absence", value: "0.0" },
  { description: "Professor logado no sistema pode lançar notas. O valor yes habilita turmas do semestre atual, yes_all_semesters habilita qualquer semestre.", variable: "professor_login_can_post_grades", value: "no" },
  { description: "Periodo da Avaliação Quadrienal", variable: "quadrennial_period", value: "2021 - 2021" },
])
ProgramLevel.create([{ level: "5", start_date: Time.now, end_date: nil }])


Role.create([
  { id: 1, name: "Desconhecido", description: "Desconhecido" },
  { id: 2, name: "Coordenação", description: "Coordenação" },
  { id: 3, name: "Secretaria", description: "Secretaria" },
  { id: 4, name: "Professor", description: "Professor" },
  { id: 5, name: "Aluno", description: "Aluno" },
  { id: 6, name: "Administrador", description: "Administrador" },
  { id: 7, name: "Suporte", description: "Suporte (inserir fotos de alunos)" },
])

user = User.new do |u|
  u.name = "admin"
  u.email = "admin@change.me"
  u.password = "admin"
  u.roles = [Role.find_by_name("Administrador")]
end
user.skip_confirmation!
user.save!

