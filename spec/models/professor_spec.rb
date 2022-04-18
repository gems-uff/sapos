# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

require Rails.root.join "spec/support/user_helpers.rb"

RSpec.configure do |c|
  c.include UserHelpers
end

describe Professor do
  before :all do
    FactoryBot.create :role_professor
  end
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :advisement_authorization }
  it { should restrict_destroy_when_exists :advisement }
  it { should restrict_destroy_when_exists :course_class }
  it { should destroy_dependent :professor_research_area }
  it { should restrict_destroy_when_exists :scholarship }
  it { should restrict_destroy_when_exists :thesis_defense_committee_participation }

  let(:professor) { Professor.new }
  subject { professor }
  describe "Validations" do
    describe "cpf" do
      context "should be valid when" do
        it "cpf is not null and is not taken" do
          professor.cpf = "Professor cpf"
          expect(professor).to have(0).errors_on :cpf
        end
      end
      context "should have error blank when" do
        it "cpf is null" do
          professor.cpf = nil
          expect(professor).to have_error(:blank).on :cpf
        end
      end
      context "should have error taken when" do
        it "cpf is already in use" do
          cpf = "Professor cpf"
          FactoryBot.create(:professor, :cpf => cpf)
          professor.cpf = cpf
          expect(professor).to have_error(:taken).on :cpf
        end
      end
    end
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          professor.name = "Professor name"
          expect(professor).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          professor.name = nil
          expect(professor).to have_error(:blank).on :name
        end
      end
    end
    describe "email" do
      context "should be valid when" do
        it "email is null" do
          professor.email = nil
          expect(professor).to have(0).errors_on :email
        end
        it "email is not null and not taken" do
          professor.email = "professor@sapos.com"
          expect(professor).to have(0).errors_on :email
        end
      end
      context "should have error taken when" do
        it "email is already in use" do
          other_professor = FactoryBot.create(:professor, :email => "professor@sapos.com")
          professor.email = other_professor.email
          expect(professor).to have_error(:taken).on :email
        end
      end
    end
    describe "enrollment_number" do
      context "should be valid when" do
        it "enrollment_number is null" do
          professor.enrollment_number = nil
          expect(professor).to have(0).errors_on :enrollment_number
        end
        it "enrollment_number is not null and not taken" do
          professor.enrollment_number = "Professor Enrollment Number"
          expect(professor).to have(0).errors_on :enrollment_number
        end
      end
      context "should have error taken when" do
        it "enrollment_number is already in use" do
          other_professor = FactoryBot.create(:professor, :enrollment_number => "Enrollment number")
          professor.enrollment_number = other_professor.enrollment_number
          expect(professor).to have_error(:taken).on :enrollment_number
        end
      end
    end
    describe "user" do
      context "should be valid when" do
        it "user is null" do
          delete_users_by_emails ['abc@def.com']
          #user = FactoryBot.create(:user, :email => 'abc@def.com', :role_id => Role::ROLE_ALUNO)
          professor.user = nil
          expect(professor).to have(0).errors_on :user
        end
        it "user is set to null after a predefined vaule" do
          delete_users_by_emails ['abc@def.com', 'def@ghi.com']
          user1 = FactoryBot.create(:user, :email => 'abc@def.com', :role_id => Role::ROLE_PROFESSOR)
          professor.user = user1
          professor.save(validate: false)
          professor.user = nil
          expect(professor).to have(0).errors_on :user
        end

      end
      context "should have error changed_to_different_user when" do
        it "user is set to a different user" do
          delete_users_by_emails ['abc@def.com', 'def@ghi.com']
          user1 = FactoryBot.create(:user, :email => 'abc@def.com', :role_id => Role::ROLE_PROFESSOR)
          user2 = FactoryBot.create(:user, :email => 'def@ghi.com', :role_id => Role::ROLE_PROFESSOR)
          professor.user = user1
          professor.save(validate: false)
          professor.user = user2
          expect(professor).to have_error(:changed_to_different_user).on :user
        end
      end
    end
  end
  describe "Methods" do
    describe "advisement_points" do
      it "should return 0 if the professor has no advisement_authorizations" do
        expect(professor.advisement_points).to eql("0.0")
      end
      it "should return the spected number if the professor has advisement_authorizations (default)" do
        professor = FactoryBot.create(:professor)
        other_professor = FactoryBot.create(:professor)
        enrollment = FactoryBot.create(:enrollment)
        other_enrollment = FactoryBot.create(:enrollment, :level => enrollment.level)

        FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryBot.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryBot.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryBot.create(:advisement, :professor => professor, :enrollment => other_enrollment)

        FactoryBot.create(:advisement, :professor => other_professor, :enrollment => other_enrollment, :main_advisor => false)

        expect(professor.advisement_points).to eql("1.5")
      end

      it "should return the spected number if the professor has advisement_authorizations and the points are changed" do
        config = CustomVariable.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        config = CustomVariable.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        CustomVariable.create(:variable=>:single_advisor_points, :value=>"2.0")
        CustomVariable.create(:variable=>:multiple_advisor_points, :value=>"1.0")

        professor = FactoryBot.create(:professor)
        other_professor = FactoryBot.create(:professor)
        enrollment = FactoryBot.create(:enrollment)
        other_enrollment = FactoryBot.create(:enrollment, :level => enrollment.level)

        FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryBot.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryBot.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryBot.create(:advisement, :professor => professor, :enrollment => other_enrollment)

        FactoryBot.create(:advisement, :professor => other_professor, :enrollment => other_enrollment, :main_advisor => false)

        expect(professor.advisement_points).to eql("3.0")
      end

      describe "test total points with included level parameter" do
        before(:each) do
          config = CustomVariable.find_by_variable(:single_advisor_points)
          config.delete unless config.nil?
          config = CustomVariable.find_by_variable(:multiple_advisor_points)
          config.delete unless config.nil?
          CustomVariable.create(:variable=>:single_advisor_points, :value=>"1.0")
          CustomVariable.create(:variable=>:multiple_advisor_points, :value=>"0.5")

          @level1 = FactoryBot.create(:level)
          @level2 = FactoryBot.create(:level)

          @professor1 = FactoryBot.create(:professor)
          @professor2 = FactoryBot.create(:professor)
          @professor3 = FactoryBot.create(:professor)

          FactoryBot.create(:advisement_authorization, :professor => @professor1, :level => @level1)
          FactoryBot.create(:advisement_authorization, :professor => @professor2, :level => @level2)

          enrollment1 = FactoryBot.create(:enrollment, :level => @level1)
          enrollment2 = FactoryBot.create(:enrollment, :level => @level2)

          FactoryBot.create(:advisement, :professor => @professor1, :enrollment => enrollment1)
          FactoryBot.create(:advisement, :professor => @professor1, :enrollment => enrollment2, :main_advisor => false)
          FactoryBot.create(:advisement, :professor => @professor2, :enrollment => enrollment2)
          FactoryBot.create(:advisement, :professor => @professor3, :enrollment => enrollment1, :main_advisor => false)
          FactoryBot.create(:advisement, :professor => @professor3, :enrollment => enrollment2, :main_advisor => false)
        end

        it "should return 1.5 total points to authorized professor with one single and one multiple advisements" do
          expect(@professor1.advisement_points).to eql("1.5")
        end

        it "should return 1.0 level points to authorized professor with single advisement on level" do
          expect(@professor1.advisement_points(@level1.id)).to eql("1.0")
        end

        it "should return 0.5 level points to authorized professor with multiple advisement on level, is not the main advisor" do
          expect(@professor1.advisement_points(@level2.id)).to eql("0.5")
        end

        it "should return 0.5 total points to authorized professor with one multiple advisement" do
          expect(@professor2.advisement_points).to eql("0.5")
        end

        it "should return 0.5 level points to authorized professor with multiple advisement on level, is the main advisor" do
          expect(@professor2.advisement_points(@level2.id)).to eql("0.5")
        end

        it "should return 0.0 level-1 points to professor which is autorized only in level-2" do
          expect(@professor2.advisement_points(@level1.id)).to eql("0.0")
        end

        it "should return 0.0 total points to not authorized professor" do
          expect(@professor3.advisement_points).to eql("0.0")
        end

        it "should return 0.0 level-1 points to professor not autorized in level-1" do
          expect(@professor3.advisement_points(@level1.id)).to eql("0.0")
        end

        it "should return 0.0 level-2 points to professor not autorized in level-2" do
          expect(@professor3.advisement_points(@level2.id)).to eql("0.0")
        end
      end

    end
    describe "advisement_point" do
      context "should return 0 when" do
        it "the professor has no advisement_authorizations" do
          enrollment = FactoryBot.create(:enrollment)
          expect(professor.advisement_point(enrollment)).to eql(0.0)
        end
        it "the enrollment is not advised by the professor" do
          professor = FactoryBot.create(:professor)
          other_professor = FactoryBot.create(:professor)
          enrollment = FactoryBot.create(:enrollment)
          FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
          FactoryBot.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)
          FactoryBot.create(:advisement, :professor => other_professor, :enrollment => enrollment)

          expect(professor.advisement_point(enrollment)).to eql(0.0)
        end
        it "the enrollment have a dismissal" do
          professor = FactoryBot.create(:professor)
          enrollment = FactoryBot.create(:enrollment)
          FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
          FactoryBot.create(:advisement, :professor => professor, :enrollment => enrollment)
          FactoryBot.create(:dismissal, :enrollment => enrollment)

          expect(professor.advisement_point(enrollment)).to eql(0.0)
        end
      end
      it "should return 1 when the professor is the only authorized advisor (default)" do

        professor = FactoryBot.create(:professor)
        other_professor = FactoryBot.create(:professor)
        enrollment = FactoryBot.create(:enrollment)

        FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)

        FactoryBot.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryBot.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        expect(professor.advisement_point(enrollment)).to eql(1.0)
      end

      it "should return the configured value when the professor is the only authorized advisor" do
        config = CustomVariable.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        CustomVariable.create(:variable=>:single_advisor_points, :value=>"2.0")

        professor = FactoryBot.create(:professor)
        other_professor = FactoryBot.create(:professor)
        enrollment = FactoryBot.create(:enrollment)

        FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)

        FactoryBot.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryBot.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        expect(professor.advisement_point(enrollment)).to eql(2.0)
      end      

      it "should return 0.5 when the professor is not the only authorized advisor (default)" do
        professor = FactoryBot.create(:professor)
        other_professor = FactoryBot.create(:professor)
        enrollment = FactoryBot.create(:enrollment)

        FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryBot.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryBot.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryBot.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        expect(professor.advisement_point(enrollment)).to eql(0.5)
      end

      it "should return the configured value when the professor is not the only authorized advisor" do
        config = CustomVariable.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        CustomVariable.create(:variable=>:multiple_advisor_points, :value=>"1.0")

        professor = FactoryBot.create(:professor)
        other_professor = FactoryBot.create(:professor)
        enrollment = FactoryBot.create(:enrollment)

        FactoryBot.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryBot.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryBot.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryBot.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        expect(professor.advisement_point(enrollment)).to eql(1.0)
      end
    end
  end
end
