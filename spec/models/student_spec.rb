# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Student, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:student_majors).dependent(:destroy) }
  it { should have_many(:majors).through(:student_majors) }
  it { should have_many(:enrollments).dependent(:restrict_with_exception) }

  before(:all) do
    @destroy_later = []
    @role_aluno = FactoryBot.create :role_aluno
    @role = FactoryBot.create(:role)
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @role_aluno.delete
    @role.delete
  end
  let(:student) do
    Student.new(
      name: "Ana",
      cpf: "a123.456.789-10"
    )
  end
  subject { student }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:city).required(false) }
    it { should belong_to(:birth_city).required(false) }
    it { should belong_to(:birth_state).required(false) }
    it { should belong_to(:birth_country).required(false) }
    it { should belong_to(:user).required(false) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:cpf) }
    it { should validate_presence_of(:cpf) }

    describe "user" do
      context "should be valid when" do
        it "user is set to null after a predefined value" do
          @destroy_later << user1 = FactoryBot.create(:user, email: "abc@def.com", role_id: Role::ROLE_ALUNO)
          student.user = user1
          student.save(validate: false)
          @destroy_later << student
          student.user = nil
          expect(student).to have(0).errors_on :user
        end
      end
      context "should have error changed_to_different_user when" do
        it "user is set to a different user" do
          # delete_users_by_emails ["abc@def.com", "def@ghi.com"]
          @destroy_later << user1 = FactoryBot.create(:user, email: "abc@def.com", role_id: Role::ROLE_ALUNO)
          @destroy_later << user2 = FactoryBot.create(:user, email: "def@ghi.com", role_id: Role::ROLE_ALUNO)
          student.user = user1
          student.save(validate: false)
          @destroy_later << student
          student.user = user2
          expect(student).to have_error(:changed_to_different_user).on :user
        end
      end
    end
  end
  describe "Methods" do
    describe "emails" do
      it "should return an empty list when no email is stored" do
        student.email = ""
        expect(student.emails).to eq([])
      end

      it "should return a list with one email when a single one is stored" do
        student.email = "abc@def.com"
        expect(student.emails).to eq(["abc@def.com"])
      end

      it "should return a list of emails when multiple are stored" do
        student.email = "abc@def.com def@ghi.com, ghi@jkl.com;jkl@mno.com"
        expect(student.emails).to eq(["abc@def.com", "def@ghi.com", "ghi@jkl.com", "jkl@mno.com"])
      end
    end

    describe "first_email" do
      it "should return nil when no email is stored" do
        student.email = ""
        expect(student.first_email).to eq(nil)
      end

      it "should return the email when a single one is stored" do
        student.email = "abc@def.com"
        expect(student.first_email).to eq("abc@def.com")
      end

      it "should return the first email when multiple are stored" do
        student.email = "abc@def.com def@ghi.com, ghi@jkl.com;jkl@mno.com"
        expect(student.first_email).to eq("abc@def.com")
      end
    end

    describe "can_have_new_user?" do
      it "should return true if the student has an active enrollment that allows users and has no associated user" do
        student.email = "abc@def.com"
        expect(student.can_have_new_user?).to eq(true)
      end
      it "should return false if the student has the same email as an user" do
        @destroy_later << FactoryBot.create(:user, email: "abc@def.com", role: @role)
        student.email = "abc@def.com"
        expect(student.can_have_new_user?).to eq(false)
      end
      it "should return false if the student has the same email as an user among a list of emails" do
        @destroy_later << FactoryBot.create(:user, email: "def@ghi.com", role: @role)
        student.email = "abc@def.com;def@ghi.com"
        expect(student.can_have_new_user?).to eq(false)
      end
      it "should return false if the student already has an user" do
        student.email = "abc@def.com"
        @destroy_later << student.user = FactoryBot.create(:user, email: "def@ghi.com", role: @role)
        expect(student.can_have_new_user?).to eq(false)
      end
    end

    describe "enrollments_number" do
      it "should return the enrollment number when the student has one enrollment" do
        @destroy_later << FactoryBot.create(:enrollment, enrollment_number: "M123", student: student)
        expect(student.enrollments_number).to eq("M123")
      end

      it "should return the enrollments number separated by comma when the student has two enrollments" do
        @destroy_later << FactoryBot.create(:enrollment, enrollment_number: "M123", student: student)
        @destroy_later << FactoryBot.create(:enrollment, enrollment_number: "D234", student: student)
        expect(student.enrollments_number).to eq("M123, D234")
      end
    end

    describe "birthplace" do
      it "should return country, when birth_city is specified" do
        city = FactoryBot.build(:city)
        student.birth_city = city
        expect(student.birthplace).to eq("#{city.state.country.name}")
      end
      it "should return country, when birth_city is not specified" do
        state = FactoryBot.build(:state)
        student.birth_state = state
        expect(student.birthplace).to eq("#{state.country.name}")
      end
      it "should return nil when neither birth_city and birth_state are specified" do
        expect(student.birthplace).to be_nil
      end
    end
  end
  describe "Before save" do
    it "should set the birth_state when birth_city is filled" do
      @destroy_later << birth_city = FactoryBot.create(:city)
      @destroy_later << birth_state = FactoryBot.create(:state)
      student.birth_state = birth_state
      student.birth_city = nil
      student.birth_city = birth_city
      expect(student.birth_state).to eq(birth_state)

      student.save
      @destroy_later << student
      expect(student.birth_state).to eq(birth_city.state)
      expect(student.birth_state).not_to eq(birth_state)
    end

    it "should not set the birth_state when birth_city is not filled" do
      @destroy_later << birth_state = FactoryBot.create(:state)
      student.birth_state = birth_state
      student.birth_city = nil
      expect(student.birth_state).to eq(birth_state)
      student.save
      @destroy_later << student
      expect(student.birth_state).to eq(birth_state)
    end
  end
end
