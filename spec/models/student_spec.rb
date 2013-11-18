# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Student do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :enrollment }
  it { should restrict_destroy_when_exists :student_major }

  let(:student) { Student.new }
  subject { student }
  describe "Validations" do
    describe "cpf" do
      context "should be valid when" do
        it "cpf is not null and is not taken" do
          student.cpf = "Student cpf"
          student.should have(0).errors_on :cpf
        end
      end
      context "should have error blank when" do
        it "cpf is null" do
          student.cpf = nil
          student.should have_error(:blank).on :cpf
        end
      end
      context "should have error taken when" do
        it "cpf is already in use" do
          cpf = "Student cpf"
          FactoryGirl.create(:student, :cpf => cpf)
          student.cpf = cpf
          student.should have_error(:taken).on :cpf
        end
      end
    end
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          student.name = "Student name"
          student.should have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          student.name = nil
          student.should have_error(:blank).on :name
        end
      end
      end
  end
  describe "Methods" do
    describe "enrollments_number" do
      it "should return the enrollment number when the student has one enrollment" do
        student = FactoryGirl.create(:student)
        FactoryGirl.create(:enrollment, :enrollment_number => "M123", :student => student)
        student.enrollments_number.should == "M123"
      end

      it "should return the enrollments number separated by comma when the student has two enrollments" do
        student = FactoryGirl.create(:student)
        FactoryGirl.create(:enrollment, :enrollment_number => "M123", :student => student)
        FactoryGirl.create(:enrollment, :enrollment_number => "D234", :student => student)
        student.enrollments_number.should == "M123, D234"
      end
    end

    describe "birthplace" do
      it "should return city, state, country, when birth_city is specified" do
        city = FactoryGirl.create(:city)
        student = FactoryGirl.create(:student, :birth_city => city)
        student.birthplace.should == "#{city.name}, #{city.state.name}, #{city.state.country.name}"
      end
      it "should return city, state, country, when birth_city is not specified" do
        state = FactoryGirl.create(:state)
        student = FactoryGirl.create(:student, :birth_state => state)
        student.birthplace.should == "#{state.name}, #{state.country.name}"
      end
      it "should return nil when neither birth_city and birth_state are specified" do
        student = FactoryGirl.create(:student)
        student.birthplace.should be_nil
      end
    end
  end
  describe "Before save" do
    it "should set the birth_state when birth_city is filled" do
      birth_city = FactoryGirl.create(:city)
      birth_state = FactoryGirl.create(:state)
      student = FactoryGirl.build(:student, :birth_state => birth_state, :birth_city => nil)
      student.birth_city = birth_city
      student.birth_state.should == birth_state

      student.save
      student.birth_state.should == birth_city.state
      student.birth_state.should_not == birth_state
    end

    it "should not set the birth_state when birth_city is not filled" do
      birth_state = FactoryGirl.create(:state)
      student = FactoryGirl.build(:student, :birth_state => birth_state, :birth_city => nil)
      student.birth_state.should == birth_state
      student.save
      student.birth_state.should == birth_state
    end
  end
end