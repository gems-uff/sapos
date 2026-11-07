# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Rotulos usados em documento e no mapeamento de candidato para aluno, sem
# exemplo (#720): nome completo de pais e estado (FilledFormField grava no aluno
# o local de nascimento por eles), nome do curso no nivel (historico em PDF) e
# a nacionalidade do aluno pelo local de nascimento (historico em PDF).
RSpec.describe "Rotulos de local, nivel e nacionalidade", type: :model do
  before(:each) do
    @pais = FactoryBot.create(:country, name: "Brasil", nationality: "brasileira")
    @estado = FactoryBot.create(:state, name: "Rio de Janeiro", country: @pais)
    @cidade = FactoryBot.create(:city, name: "Niteroi", state: @estado)
  end

  it "nome completo do pais e o nome" do
    expect(@pais.full_name).to eq("Brasil")
  end

  it "nome completo do estado traz o pais" do
    expect(@estado.full_name).to eq("Rio de Janeiro, Brasil")
  end

  it "nome completo do nivel e o nome do curso quando ha um" do
    expect(FactoryBot.build(:level, name: "Mestrado", course_name: "Mestrado em Computacao").full_name)
      .to eq("Mestrado em Computacao")
    expect(FactoryBot.build(:level, name: "Mestrado", course_name: "").full_name).to eq("Mestrado")
  end

  describe "nacionalidade do aluno" do
    it "vem do pais de nascimento" do
      expect(FactoryBot.build(:student, birth_country: @pais).nationality).to eq("brasileira")
    end

    it "vem do pais do estado de nascimento, sem pais" do
      expect(FactoryBot.build(:student, birth_state: @estado).nationality).to eq("brasileira")
    end

    it "vem do pais da cidade de nascimento, sem pais nem estado" do
      expect(FactoryBot.build(:student, birth_city: @cidade).nationality).to eq("brasileira")
    end

    it "e nil sem local de nascimento" do
      expect(FactoryBot.build(:student).nationality).to be_nil
    end
  end
end

RSpec.describe Phase, "prazo estendido por trancamento", type: :model do
  before(:each) do
    @nivel = FactoryBot.create(:level)
    @matricula = FactoryBot.create(:enrollment, level: @nivel, admission_date: Date.new(2020, 3, 1))
    FactoryBot.create(:enrollment_hold, enrollment: @matricula, year: 2021, semester: 1, number_of_semesters: 2)
  end

  def fase(estende)
    fase = FactoryBot.create(:phase, extend_on_hold: estende)
    FactoryBot.create(:phase_duration, phase: fase, level: @nivel, deadline_semesters: 4, deadline_months: 0, deadline_days: 0)
    fase
  end

  it "soma os semestres trancados quando a fase estende" do
    expect(fase(true).total_duration(@matricula.reload)[:semesters]).to eq(6)
  end

  it "ignora o trancamento posterior a data de corte" do
    expect(fase(true).total_duration(@matricula.reload, until_date: Date.new(2020, 6, 1))[:semesters]).to eq(4)
  end

  it "nao soma quando a fase nao estende" do
    expect(fase(false).total_duration(@matricula.reload)[:semesters]).to eq(4)
  end
end
