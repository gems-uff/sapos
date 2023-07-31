# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.
# frozen_string_literal: true

require "spec_helper"

RSpec.describe Phase, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:accomplishments).dependent(:restrict_with_exception) }
  it { should have_many(:enrollments).through(:accomplishments) }
  it { should have_many(:phase_durations).dependent(:destroy) }
  it { should have_many(:levels).through(:phase_durations) }
  it { should have_many(:deferral_type).dependent(:restrict_with_exception) }
  it { should have_many(:phase_completions).dependent(:destroy) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  let(:name) { "Pedido de Banca" }
  let(:phase) { Phase.new(name: name) }
  subject { phase }
  describe "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should allow_value([true, false]).for(:active) }
    it { is_expected.not_to allow_value(nil).for(:active) }

    describe "active" do
      context "should be valid when" do
        it "active value is true" do
          phase.name = true
          expect(phase).to have(0).errors_on :active
        end
        it "active value is false" do
          phase.name = false
          expect(phase).to have(0).errors_on :active
        end
      end

      context "should be invalid when" do
        it "active is null" do
          phase.active = nil
          expect(phase).to have(1).errors_on :active
        end
      end
    end
  end

  describe "Class methods" do
    describe "find_all_for_enrollment" do
      it "should return all phases if enrollment is nil" do
        @destroy_later << FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase)

        phases = Phase.where(Phase.find_all_for_enrollment(nil))
        expect(phases.count).to eq(Phase.count)
      end

      it "should return phases that have the same level as the enrollment" do
        @destroy_later << level1 = FactoryBot.create(:level)
        @destroy_later << level2 = FactoryBot.create(:level)

        @destroy_later << phase1 = FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase1, level: level1)

        @destroy_later << phase2 = FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase2, level: level1)

        @destroy_later << phase3 = FactoryBot.create(:phase)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase3, level: level2)

        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level1)

        phases = Phase.where(Phase.find_all_for_enrollment(enrollment))
        expect(phases.count).to eq(2)
      end

      it "should not return an inactivated phase if enrollment is nil" do
        @destroy_later << FactoryBot.create(:phase, active: false)
        phases = Phase.where(Phase.find_all_for_enrollment(nil))
        expect(phases.count).to eq(0)
      end

      it "should not return an inactivated phase that have the same level as the enrollment" do
        @destroy_later << level1 = FactoryBot.create(:level)

        @destroy_later << phase1 = FactoryBot.create(:phase, active: false)
        @destroy_later << FactoryBot.create(:phase_duration, phase: phase1, level: level1)

        @destroy_later << enrollment = FactoryBot.create(:enrollment, level: level1)

        phases = Phase.where(Phase.find_all_for_enrollment(enrollment))
        expect(phases.count).to eq(0)
      end
    end
  end
end
