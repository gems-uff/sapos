# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProgramLevel, type: :model do
  it { should be_able_to_be_destroyed }

  let(:program_level) { ProgramLevel.new(level: 1, start_date: Date.today) }
  subject { program_level }

  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:level) }
    it { should validate_presence_of(:start_date) }
  end

  describe "Scopes" do
    before(:all) do
      @active = FactoryBot.create(:program_level, start_date: Date.new(2020, 1, 1), end_date: nil)
      @inactive = FactoryBot.create(:program_level, start_date: Date.new(2020, 1, 1), end_date: Date.new(2022, 1, 1))
      @future = FactoryBot.create(:program_level, start_date: Date.new(2030, 1, 1), end_date: nil)
    end

    after(:all) do
      @active.delete
      @inactive.delete
      @future.delete
    end

    describe "active" do
      it "returns only records with nil end_date" do
        result = ProgramLevel.active
        expect(result).to include(@active, @future)
        expect(result).not_to include(@inactive)
      end
    end

    describe "on_date" do
      it "returns records whose range covers the given date" do
        result = ProgramLevel.on_date(Date.new(2024, 6, 15))
        expect(result).to include(@active)
        expect(result).not_to include(@inactive, @future)
      end

      it "includes records with open end_date on future dates" do
        result = ProgramLevel.on_date(Date.new(2024, 6, 15))
        expect(result).to include(@active)
      end

      it "includes an expired record when the query date precedes end_date" do
        result = ProgramLevel.on_date(Date.new(2021, 6, 15))
        expect(result).to include(@inactive, @active)
        expect(result).not_to include(@future)
      end
    end
  end

  describe "Methods" do
    describe "to_label" do
      it "includes the level value" do
        program_level.level = 3
        expect(program_level.to_label).to include("3")
      end
    end

    describe "to_ordinance" do
      it "wraps ordinance in parentheses when present" do
        program_level.ordinance = "Portaria 109/2025"
        expect(program_level.to_ordinance).to eq("(Portaria 109/2025)")
      end

      it "returns empty string when ordinance is nil" do
        program_level.ordinance = nil
        expect(program_level.to_ordinance).to eq("")
      end
    end
  end
end
