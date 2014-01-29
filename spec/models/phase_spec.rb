# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Phase do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :accomplishment }
  it { should restrict_destroy_when_exists :deferral_type }
  it { should destroy_dependent :phase_duration }

  let(:phase) { Phase.new }
  subject { phase }
  describe "Validations" do
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          phase.name = "Phase name"
          phase.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          phase.name = nil
          phase.should have_error(:blank).on :name
        end
      end
      context "should have error taken when" do
        it "name is already in use" do
          name = "Phase name"
          FactoryGirl.create(:phase, :name => name)
          phase.name = name
          phase.should have_error(:taken).on :name
        end
      end
    end
  end

  describe "Class methods" do
    describe "find_all_for_enrollment" do
      it "should return all phases if enrollment is nil" do
        FactoryGirl.create(:phase)
        FactoryGirl.create(:phase)
        FactoryGirl.create(:phase)
        
        phases = Phase.where(Phase::find_all_for_enrollment(nil))
        phases.count.should == Phase.count
      end

      it "should return phases that have the same level as the enrollment" do
        level1 = FactoryGirl.create(:level)
        level2 = FactoryGirl.create(:level)
        
        phase1 = FactoryGirl.create(:phase)
        FactoryGirl.create(:phase_duration, :phase => phase1, :level => level1)
          
        phase2 = FactoryGirl.create(:phase)
        FactoryGirl.create(:phase_duration, :phase => phase2, :level => level1)
          
        phase3 = FactoryGirl.create(:phase)
        FactoryGirl.create(:phase_duration, :phase => phase3, :level => level2)
         
        enrollment = FactoryGirl.create(:enrollment, :level => level1) 
        
        phases = Phase.where(Phase::find_all_for_enrollment(enrollment))
        phases.count.should == 2
      end
    end
  end
end