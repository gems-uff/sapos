# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::RankingMachine, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:ranking_processes).dependent(:destroy) }
  it { should belong_to(:form_condition).required(false) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:ranking_machine) do
    Admissions::RankingMachine.new(
      name: "Máquina de Ranqueamento"
    )
  end
  subject { ranking_machine }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
  end
  # ToDo: initialize_dup

  describe "Methods" do
    describe "to_label" do
      it "returns the correct label" do
        ranking_machine.name = "Máquina"
        expect(ranking_machine.to_label).to eq("Máquina")
      end
    end
  end
end
