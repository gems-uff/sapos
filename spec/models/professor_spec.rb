# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Professor do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :advisement_authorization }
  it { should restrict_destroy_when_exists :advisement }
  it { should restrict_destroy_when_exists :course_class }
  it { should restrict_destroy_when_exists :professor_research_area }
  it { should restrict_destroy_when_exists :scholarship }

  let(:professor) { Professor.new }
  subject { professor }
  describe "Validations" do
    describe "cpf" do
      context "should be valid when" do
        it "cpf is not null and is not taken" do
          professor.cpf = "Professor cpf"
          professor.should have(0).errors_on :cpf
        end
      end
      context "should have error blank when" do
        it "cpf is null" do
          professor.cpf = nil
          professor.should have_error(:blank).on :cpf
        end
      end
      context "should have error taken when" do
        it "cpf is already in use" do
          cpf = "Professor cpf"
          FactoryGirl.create(:professor, :cpf => cpf)
          professor.cpf = cpf
          professor.should have_error(:taken).on :cpf
        end
      end
    end
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          professor.name = "Professor name"
          professor.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          professor.name = nil
          professor.should have_error(:blank).on :name
        end
      end
    end
    describe "enrollment_number" do
      context "should be valid when" do
        it "enrollment_number is null" do
          professor.enrollment_number = nil
          professor.should have(0).errors_on :enrollment_number
        end
        it "enrollment_number is not null and not taken" do
          professor.enrollment_number = "Professor Enrollment Number"
          professor.should have(0).errors_on :enrollment_number
        end
      end
      context "should have error taken when" do
        it "enrollment_number is already in use" do
          other_professor = FactoryGirl.create(:professor, :enrollment_number => "Enrollment number")
          professor.enrollment_number = other_professor.enrollment_number
          professor.should have_error(:taken).on :enrollment_number
        end
      end
    end
  end
  describe "Methods" do
    describe "advisement_points" do
      it "should return 0 if the professor has no advisement_authorizations" do
        professor.advisement_points.should eql("0.0")
      end
      it "should return the spected number if the professor has advisement_authorizations (default)" do
        professor = FactoryGirl.create(:professor)
        other_professor = FactoryGirl.create(:professor)
        enrollment = FactoryGirl.create(:enrollment)
        other_enrollment = FactoryGirl.create(:enrollment, :level => enrollment.level)

        FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryGirl.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryGirl.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryGirl.create(:advisement, :professor => professor, :enrollment => other_enrollment)

        FactoryGirl.create(:advisement, :professor => other_professor, :enrollment => other_enrollment, :main_advisor => false)

        professor.advisement_points.should eql("1.5")
      end

      it "should return the spected number if the professor has advisement_authorizations and the points are changed" do
        config = Configuration.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        config = Configuration.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        Configuration.create(:variable=>:single_advisor_points, :value=>"2.0")
        Configuration.create(:variable=>:multiple_advisor_points, :value=>"1.0")

        professor = FactoryGirl.create(:professor)
        other_professor = FactoryGirl.create(:professor)
        enrollment = FactoryGirl.create(:enrollment)
        other_enrollment = FactoryGirl.create(:enrollment, :level => enrollment.level)

        FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryGirl.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryGirl.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryGirl.create(:advisement, :professor => professor, :enrollment => other_enrollment)

        FactoryGirl.create(:advisement, :professor => other_professor, :enrollment => other_enrollment, :main_advisor => false)

        professor.advisement_points.should eql("3.0")
      end
    end
    describe "advisement_point" do
      context "should return 0 when" do
        it "the professor has no advisement_authorizations" do
          enrollment = FactoryGirl.create(:enrollment)
          professor.advisement_point(enrollment).should eql(0.0)
        end
        it "the enrollment is not advised by the professor" do
          professor = FactoryGirl.create(:professor)
          other_professor = FactoryGirl.create(:professor)
          enrollment = FactoryGirl.create(:enrollment)
          FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
          FactoryGirl.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)
          FactoryGirl.create(:advisement, :professor => other_professor, :enrollment => enrollment)

          professor.advisement_point(enrollment).should eql(0.0)
        end
        it "the enrollment have a dismissal" do
          professor = FactoryGirl.create(:professor)
          enrollment = FactoryGirl.create(:enrollment)
          FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
          FactoryGirl.create(:advisement, :professor => professor, :enrollment => enrollment)
          FactoryGirl.create(:dismissal, :enrollment => enrollment)

          professor.advisement_point(enrollment).should eql(0.0)
        end
      end
      it "should return 1 when the professor is the only authorized advisor (default)" do

        professor = FactoryGirl.create(:professor)
        other_professor = FactoryGirl.create(:professor)
        enrollment = FactoryGirl.create(:enrollment)

        FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)

        FactoryGirl.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryGirl.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        professor.advisement_point(enrollment).should eql(1.0)
      end

      it "should return the configured value when the professor is the only authorized advisor" do
        config = Configuration.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        Configuration.create(:variable=>:single_advisor_points, :value=>"2.0")

        professor = FactoryGirl.create(:professor)
        other_professor = FactoryGirl.create(:professor)
        enrollment = FactoryGirl.create(:enrollment)

        FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)

        FactoryGirl.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryGirl.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        professor.advisement_point(enrollment).should eql(2.0)
      end      

      it "should return 0.5 when the professor is not the only authorized advisor (default)" do
        professor = FactoryGirl.create(:professor)
        other_professor = FactoryGirl.create(:professor)
        enrollment = FactoryGirl.create(:enrollment)

        FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryGirl.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryGirl.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryGirl.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        professor.advisement_point(enrollment).should eql(0.5)
      end

      it "should return the configured value when the professor is not the only authorized advisor" do
        config = Configuration.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        Configuration.create(:variable=>:multiple_advisor_points, :value=>"1.0")

        professor = FactoryGirl.create(:professor)
        other_professor = FactoryGirl.create(:professor)
        enrollment = FactoryGirl.create(:enrollment)

        FactoryGirl.create(:advisement_authorization, :professor => professor, :level => enrollment.level)
        FactoryGirl.create(:advisement_authorization, :professor => other_professor, :level => enrollment.level)

        FactoryGirl.create(:advisement, :professor => professor, :enrollment => enrollment)
        FactoryGirl.create(:advisement, :professor => other_professor, :enrollment => enrollment, :main_advisor => false)

        professor.advisement_point(enrollment).should eql(1.0)
      end


    end
  end
end