# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Student do
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
end