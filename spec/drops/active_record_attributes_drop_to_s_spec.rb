# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Template Liquid que imprime um registro inteiro ({{ record.enrollment.student }})
# chama o to_s do drop, que lista os atributos. Para drop sem relacao declarada
# (StudentDrop, entre outros) o to_s faz nil.each; para relacao "muitos"
# (CourseClassDrop#class_enrollments) chama .name num Array. O leitor do e-mail
# ve "Liquid error: internal".
RSpec.describe ActiveRecordAttributesDrop, "impressao do registro inteiro" do
  # Controle: o drop com relacoes declaradas imprime os atributos.
  it "imprime a matricula, que declara relacao" do
    matricula = FactoryBot.create(:enrollment, enrollment_number: "M-DROP-1")

    expect(EnrollmentDrop.new(matricula).to_s).to include("M-DROP-1")
  end

  it "imprime o aluno, que nao declara relacao", pending: "issue #729" do
    aluno = FactoryBot.create(:student, name: "Aluno Drop")

    expect { StudentDrop.new(aluno).to_s }.not_to raise_error
    expect(StudentDrop.new(aluno).to_s).to include("Aluno Drop")
  end

  it "imprime a turma, que declara relacao de muitos", pending: "issue #729" do
    turma = FactoryBot.create(:course_class)

    expect { CourseClassDrop.new(turma).to_s }.not_to raise_error
  end
end
