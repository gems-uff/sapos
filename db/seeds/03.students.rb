# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

Level.create([
  { name: "Graduação", course_name: "Graduação", default_duration: 0 },
  { name: "Especialização", course_name: "Especialização", default_duration: 0 },
  { name: "Mestrado", course_name: "Mestrado", default_duration: 24 },
  { name: "Doutorado", course_name: "Doutorado", default_duration: 48 },
])

DismissalReason.create([
  { name: "Titulação", description: "Aluno defendeu", show_advisor_name: true, thesis_judgement: "Aprovado" },
  { name: "Rendimento", description: "Aluno não cumpriu critérios de rendimento", show_advisor_name: false, thesis_judgement: "--" },
  { name: "Desistência", description: "Aluno desistiu", show_advisor_name: false, thesis_judgement: "--" },
  { name: "Prazo", description: "Prazo para defesa esgotado", show_advisor_name: false, thesis_judgement: "--" },
  { name: "Especial/Avulso -> Regular", description: "Aluno foi admitido como aluno regular", show_advisor_name: false, thesis_judgement: "--" },
  { name: "Mudança de nível sem defesa", description: "Passagem direta ao doutorado sem defesa", show_advisor_name: true, thesis_judgement: "--" },
  { name: "Regular -> Avulso", description: "Passagem de aluno regular para avulso, por incapacidade do aluno em cursar o número mínimo de disciplinas exigidas, ou por solicitação do aluno", show_advisor_name: false, thesis_judgement: "--" },
  { name: "Falecimento", description: "Aluno faleceu", show_advisor_name: false, thesis_judgement: "--" },
])

EnrollmentStatus.create([
  { name: "Avulso", user: false },
  { name: "Regular", user: false },
  { name: "Especial", user: false },
])
