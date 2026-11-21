# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Validacoes de modelo cujo ramo de recusa nenhum exemplo percorria (#720).
# Cada recusa vem com o controle do caso aceito, para que o vermelho aponte a
# regra e nao a montagem.

RSpec.describe Assertion, "gerada pelo aluno", type: :model do
  def assercao(nome_do_parametro)
    query = FactoryBot.create(:query, sql: "SELECT 1 AS um")
    query.params.create!(name: nome_do_parametro, value_type: "String", default_value: "x")
    Assertion.new(
      name: "Declaracao", query: query, student_can_generate: true,
      template_type: Assertion::LIQUID, assertion_template: "texto"
    )
  end

  it "exige que o unico parametro da consulta seja matricula_aluno" do
    assertion = assercao("outro_parametro")

    expect(assertion).not_to be_valid
    expect(assertion.errors.details[:student_can_generate]).to include(error: :default_enrollment_variable_required)
  end

  it "aceita a consulta com o parametro matricula_aluno" do
    expect(assercao("matricula_aluno").errors[:student_can_generate]).to be_empty
    expect(assercao("matricula_aluno")).to be_valid
  end
end

RSpec.describe ClassEnrollment, "cantos da validacao", type: :model do
  before(:each) do
    @tipo = FactoryBot.create(:course_type, has_score: true, allow_multiple_classes: false)
    @curso = FactoryBot.create(:course, course_type: @tipo)
    @matricula = FactoryBot.create(:enrollment)
  end

  def inscricao(**atributos)
    FactoryBot.build(
      :class_enrollment, enrollment: @matricula,
      course_class: FactoryBot.create(:course_class, course: @curso), **atributos
    )
  end

  it "recusa segunda inscricao nao reprovada na mesma disciplina quando o tipo nao permite" do
    inscricao.save!

    segunda = inscricao

    expect(segunda).not_to be_valid
    expect(segunda.errors.details[:course_class]).to include(error: :multiple_class_enrollments_not_allowed)
  end

  it "aceita a segunda inscricao quando a primeira foi reprovada" do
    inscricao(situation: ClassEnrollment::DISAPPROVED, grade: 30).save!

    expect(inscricao).to be_valid
  end

  describe "reprovado por falta com nota acima do corte" do
    before(:each) do
      FactoryBot.create(:custom_variable, variable: "grade_of_disapproval_for_absence", value: "4,0")
    end

    it "recusa citando o corte com virgula" do
      reprovada = inscricao(situation: ClassEnrollment::DISAPPROVED, grade: 50, disapproved_by_absence: true)

      expect(reprovada).not_to be_valid
      expect(reprovada.errors.details[:disapproved_by_absence]).to include(
        error: :disapproved_by_absence_for_situation_disapproved, grade_of_disapproval_for_absence: "4,0"
      )
    end

    it "aceita nota no corte" do
      expect(inscricao(situation: ClassEnrollment::DISAPPROVED, grade: 40, disapproved_by_absence: true)).to be_valid
    end
  end
end

# A recusa das duas restricoes entre notas (nota minima que nao supera o corte
# de reprovacao por falta, e vice-versa) nao entra aqui: o errors.add recebe
# as opcoes como Hash posicional e levanta ArgumentError em vez de acusar o
# erro. Fica para a issue do defeito; aqui so o lado aceito e a duplicata.
RSpec.describe CustomVariable, "restricoes entre notas", type: :model do
  it "aceita nota minima acima do corte" do
    FactoryBot.create(:custom_variable, variable: "grade_of_disapproval_for_absence", value: "4,0")

    expect(FactoryBot.build(:custom_variable, variable: "minimum_grade_for_approval", value: "5,0")).to be_valid
  end

  it "aceita corte abaixo da nota minima padrao" do
    expect(FactoryBot.build(:custom_variable, variable: "grade_of_disapproval_for_absence", value: "5,9")).to be_valid
  end

  it "recusa criar uma segunda variavel de nota minima" do
    FactoryBot.create(:custom_variable, variable: "minimum_grade_for_approval", value: "6,0")

    segunda = FactoryBot.build(:custom_variable, variable: "minimum_grade_for_approval", value: "7,0")

    expect(segunda.save).to be(false)
    expect(segunda.errors.details[:base]).to include(error: :check_duplicate, variable: "minimum_grade_for_approval")
    expect(CustomVariable.where(variable: "minimum_grade_for_approval").count).to eq(1)
  end
end

RSpec.describe Enrollment, "area e linha de pesquisa divergentes", type: :model do
  it "recusa a linha que nao pertence a area escolhida" do
    area = FactoryBot.create(:research_area)
    outra_area = FactoryBot.create(:research_area)
    linha = FactoryBot.create(:research_line, research_area: outra_area)
    matricula = FactoryBot.build(:enrollment, research_area: area, research_line: linha)

    expect(matricula).not_to be_valid
    expect(matricula.errors.details[:research_area]).to include(error: :different_research_areas)
  end

  it "aceita a linha da propria area" do
    area = FactoryBot.create(:research_area)
    linha = FactoryBot.create(:research_line, research_area: area)
    matricula = FactoryBot.build(:enrollment, research_area: area, research_line: linha)

    matricula.valid?

    expect(matricula.errors.details[:research_area].to_a).not_to include(error: :different_research_areas)
  end
end

RSpec.describe EnrollmentRequest, "#destroy_request", type: :model do
  before(:each) do
    @pedido = FactoryBot.create(:enrollment_request, year: 2021, semester: 2)
  end

  it "recusa com impossible_removal quando o periodo de inscricao esta fechado" do
    quadro = FactoryBot.create(:class_schedule, year: 2021, semester: 2)

    expect(@pedido.destroy_request(quadro)).to be(false)
    expect(@pedido.errors.details[:base]).to include(error: :impossible_removal)
    expect(EnrollmentRequest.exists?(@pedido.id)).to be(true)
  end

  it "remove sem quadro de horario, quando nada impede" do
    expect(@pedido.destroy_request).to be_truthy
    expect(EnrollmentRequest.exists?(@pedido.id)).to be(false)
  end
end
