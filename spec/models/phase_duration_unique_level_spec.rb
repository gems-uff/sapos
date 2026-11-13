# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Duas duracoes do mesmo nivel na mesma etapa (issue #767): as duas gravam, e
# Phase#total_duration usa a primeira que a colecao devolver.
RSpec.describe PhaseDuration, "nivel repetido na etapa", type: :model do
  before(:each) do
    @phase = FactoryBot.create(:phase)
    @level = FactoryBot.create(:level)
    FactoryBot.create(:phase_duration, phase: @phase, level: @level, deadline_semesters: 4, deadline_days: 0)
  end

  it "controle: outro nivel na mesma etapa e valido" do
    expect(FactoryBot.build(:phase_duration, phase: @phase, level: FactoryBot.create(:level))).to be_valid
  end

  it "controle: o mesmo nivel em outra etapa e valido" do
    expect(FactoryBot.build(:phase_duration, phase: FactoryBot.create(:phase), level: @level)).to be_valid
  end

  it "recusa o mesmo nivel duas vezes na etapa", pending: "issue #767" do
    expect(FactoryBot.build(:phase_duration, phase: @phase, level: @level, deadline_semesters: 2)).not_to be_valid
  end
end
