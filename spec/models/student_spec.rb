# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

require Rails.root.join "spec/support/user_helpers.rb"

RSpec.configure do |c|
  c.include UserHelpers
end

describe Student do
  before :all do
    FactoryBot.create :role_aluno
  end
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :enrollment }
  it { should destroy_dependent :student_major }

  let(:student) { Student.new }
  let(:enrollment_status_with_user) { FactoryBot.create(:enrollment_status, :user => true) }
  let(:enrollment_status_without_user) { FactoryBot.create(:enrollment_status, :user => false) }
  let(:role) { FactoryBot.create(:role) }
  describe "Validations" do
    describe "cpf" do
      context "should be valid when" do
        it "cpf is not null and is not taken" do
          student.cpf = "Student cpf"
          expect(student).to have(0).errors_on :cpf
        end
      end
      context "should have error blank when" do
        it "cpf is null" do
          student.cpf = nil
          expect(student).to have_error(:blank).on :cpf
        end
      end
      context "should have error taken when" do
        it "cpf is already in use" do
          cpf = "Student cpf"
          FactoryBot.create(:student, :cpf => cpf)
          student.cpf = cpf
          expect(student).to have_error(:taken).on :cpf
        end
      end
    end
    describe "name" do
      context "should be valid when" do
        it "name is not null and is not taken" do
          student.name = "Student name"
          expect(student).to have(0).errors_on :name
        end
      end
      context "should have error blank when" do
        it "name is null" do
          student.name = nil
          expect(student).to have_error(:blank).on :name
        end
      end
    end
    describe "user" do
      context "should be valid when" do
        it "user is null" do
          delete_users_by_emails ['abc@def.com']
          #user = FactoryBot.create(:user, :email => 'abc@def.com', :role_id => Role::ROLE_ALUNO)
          student.user = nil
          expect(student).to have(0).errors_on :user
        end
        it "user is set to null after a predefined vaule" do
          delete_users_by_emails ['abc@def.com', 'def@ghi.com']
          user1 = FactoryBot.create(:user, :email => 'abc@def.com', :role_id => Role::ROLE_ALUNO)
          student.user = user1
          student.save(validate: false)
          student.user = nil
          expect(student).to have(0).errors_on :user
        end

      end
      context "should have error changed_to_different_user when" do
        it "user is set to a different user" do
          delete_users_by_emails ['abc@def.com', 'def@ghi.com']
          user1 = FactoryBot.create(:user, :email => 'abc@def.com', :role_id => Role::ROLE_ALUNO)
          user2 = FactoryBot.create(:user, :email => 'def@ghi.com', :role_id => Role::ROLE_ALUNO)
          student.user = user1
          student.save(validate: false)
          student.user = user2
          expect(student).to have_error(:changed_to_different_user).on :user
        end
      end
    end
  end
  describe "Methods" do
    describe "emails" do
      it "should return an empty list when no email is stored" do
        student = FactoryBot.create(:student, :email => '')
        expect(student.emails).to eq([])
      end

      it "should return a list with one email when a single one is stored" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        expect(student.emails).to eq(['abc@def.com'])
      end

      it "should return a list of emails when multiple are stored" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com def@ghi.com, ghi@jkl.com;jkl@mno.com')
        expect(student.emails).to eq(['abc@def.com', 'def@ghi.com', 'ghi@jkl.com', 'jkl@mno.com'])
      end
    end

    describe "first_email" do
      it "should return nil when no email is stored" do
        student = FactoryBot.create(:student, :email => '')
        expect(student.first_email).to eq(nil)
      end

      it "should return the email when a single one is stored" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        expect(student.first_email).to eq('abc@def.com')
      end

      it "should return the first email when multiple are stored" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com def@ghi.com, ghi@jkl.com;jkl@mno.com')
        expect(student.first_email).to eq('abc@def.com')
      end
    end


    describe "can_have_new_user?" do
      it "should return true if the student has an active enrollment that allows users and has no associated user" do
        user = User.find_by_email('abc@def.com')
        user.delete unless user.nil?
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        expect(student.can_have_new_user?).to eq(true)
      end
      it "should return false if the student has the same email as an user" do
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        FactoryBot.create(:user, :email => 'abc@def.com', :role => role)
        expect(student.can_have_new_user?).to eq(false)
      end
      it "should return false if the student has the same email as an user among a list of emails" do
        student = FactoryBot.create(:student, :email => 'abc@def.com;def@ghi.com')
        FactoryBot.create(:user, :email => 'def@ghi.com', :role => role)
        expect(student.can_have_new_user?).to eq(false)
      end
      it "should return false if the student already has an user" do
        student = FactoryBot.create(:student, :email => 'abc@def.com')
        student.user = FactoryBot.create(:user, :email => 'def@ghi.com', :role => role)
        expect(student.can_have_new_user?).to eq(false)
      end
      
    end

    describe "enrollments_number" do
      it "should return the enrollment number when the student has one enrollment" do
        student = FactoryBot.create(:student)
        FactoryBot.create(:enrollment, :enrollment_number => "M123", :student => student)
        expect(student.enrollments_number).to eq("M123")
      end

      it "should return the enrollments number separated by comma when the student has two enrollments" do
        student = FactoryBot.create(:student)
        FactoryBot.create(:enrollment, :enrollment_number => "M123", :student => student)
        FactoryBot.create(:enrollment, :enrollment_number => "D234", :student => student)
        expect(student.enrollments_number).to eq("M123, D234")
      end
    end

    describe "birthplace" do
      it "should return country, when birth_city is specified" do
        city = FactoryBot.create(:city)
        student = FactoryBot.create(:student, :birth_city => city)
        expect(student.birthplace).to eq("#{city.state.country.name}")
      end
      it "should return country, when birth_city is not specified" do
        state = FactoryBot.create(:state)
        student = FactoryBot.create(:student, :birth_state => state)
        expect(student.birthplace).to eq("#{state.country.name}")
      end
      it "should return nil when neither birth_city and birth_state are specified" do
        student = FactoryBot.create(:student)
        expect(student.birthplace).to be_nil
      end
    end
  end
  describe "Before save" do
    it "should set the birth_state when birth_city is filled" do
      birth_city = FactoryBot.create(:city)
      birth_state = FactoryBot.create(:state)
      student = FactoryBot.build(:student, :birth_state => birth_state, :birth_city => nil)
      student.birth_city = birth_city
      expect(student.birth_state).to eq(birth_state)

      student.save
      expect(student.birth_state).to eq(birth_city.state)
      expect(student.birth_state).not_to eq(birth_state)
    end

    it "should not set the birth_state when birth_city is not filled" do
      birth_state = FactoryBot.create(:state)
      student = FactoryBot.build(:student, :birth_state => birth_state, :birth_city => nil)
      expect(student.birth_state).to eq(birth_state)
      student.save
      expect(student.birth_state).to eq(birth_state)
    end
  end
end
