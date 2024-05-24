# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Professor, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:advisements).dependent(:restrict_with_exception) }
  it { should have_many(:enrollments).through(:advisements) }
  it { should have_many(:scholarships).dependent(:restrict_with_exception) }
  it { should have_many(:advisement_authorizations).dependent(:restrict_with_exception) }
  it { should have_many(:professor_research_areas).dependent(:destroy) }
  it { should have_many(:research_areas).through(:professor_research_areas) }
  it { should have_many(:course_classes).dependent(:restrict_with_exception) }
  it { should have_many(:thesis_defense_committee_participations).dependent(:restrict_with_exception) }
  it { should have_many(:thesis_defense_committee_enrollments).source(:enrollment).through(:thesis_defense_committee_participations) }
  it { should have_many(:affiliations).dependent(:restrict_with_exception) }
  it { should have_many(:institutions).through(:affiliations) }
  before(:all) do
    @professor_role = FactoryBot.create :role_professor
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end
  after(:all) do
    @professor_role.delete
  end

  let(:professor) do
    Professor.new(
      cpf: "a123.456.789-10",
      name: "professor",
      email: "professor@ic.uff.br",
      enrollment_number: "P1",
      )
  end
  subject { professor }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:city).required(false) }
    it { should belong_to(:academic_title_country).required(false) }
    it { should belong_to(:academic_title_institution).required(false) }
    it { should belong_to(:academic_title_level).required(false) }
    it { should belong_to(:user).required(false) }
    it { should validate_uniqueness_of(:cpf) }
    it { should validate_presence_of(:cpf) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:email).allow_nil.allow_blank }
    it { should validate_uniqueness_of(:enrollment_number).allow_blank }

    describe "user" do
      context "should be valid when" do
        it "user is null" do
          delete_users_by_emails ["abc@def.com"]
          professor.user = nil
          expect(professor).to have(0).errors_on :user
        end
        it "user is set to null after a predefined vaule" do
          delete_users_by_emails ["abc@def.com", "def@ghi.com"]
          @destroy_later << user1 = FactoryBot.create(:user, email: "abc@def.com", role_id: Role::ROLE_PROFESSOR)
          professor.user = user1
          professor.save(validate: false)
          @destroy_later << professor
          professor.user = nil
          expect(professor).to have(0).errors_on :user
        end
      end
      context "should have error changed_to_different_user when" do
        it "user is set to a different user" do
          delete_users_by_emails ["abc@def.com", "def@ghi.com"]
          @destroy_later << user1 = FactoryBot.create(:user, email: "abc@def.com", role_id: Role::ROLE_PROFESSOR)
          @destroy_later << user2 = FactoryBot.create(:user, email: "def@ghi.com", role_id: Role::ROLE_PROFESSOR)
          professor.user = user1
          professor.save(validate: false)
          @destroy_later << professor
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
        @destroy_later << professor = FactoryBot.create(:professor)
        @destroy_later << other_professor = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)
        @destroy_later << other_enrollment = FactoryBot.create(:enrollment, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: other_professor, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: other_enrollment)

        @destroy_later << FactoryBot.create(:advisement, professor: other_professor, enrollment: other_enrollment, main_advisor: false)

        expect(professor.advisement_points).to eql("1.5")
      end

      it "should return the spected number if the professor has advisement_authorizations and the points are changed" do
        config = CustomVariable.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        config = CustomVariable.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :single_advisor_points, value: "2.0")
        @destroy_later << CustomVariable.create(variable: :multiple_advisor_points, value: "1.0")

        @destroy_later << professor = FactoryBot.create(:professor)
        @destroy_later << other_professor = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)
        @destroy_later << other_enrollment = FactoryBot.create(:enrollment, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: other_professor, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: other_enrollment)

        @destroy_later << FactoryBot.create(:advisement, professor: other_professor, enrollment: other_enrollment, main_advisor: false)

        expect(professor.advisement_points).to eql("3.0")
      end

      describe "test total points with included level parameter" do
        before(:each) do
          config = CustomVariable.find_by_variable(:single_advisor_points)
          config.delete unless config.nil?
          config = CustomVariable.find_by_variable(:multiple_advisor_points)
          config.delete unless config.nil?
          @destroy_later << CustomVariable.create(variable: :single_advisor_points, value: "1.0")
          @destroy_later << CustomVariable.create(variable: :multiple_advisor_points, value: "0.5")

          @destroy_later << @level1 = FactoryBot.create(:level)
          @destroy_later << @level2 = FactoryBot.create(:level)

          @destroy_later << @professor1 = FactoryBot.create(:professor)
          @destroy_later << @professor2 = FactoryBot.create(:professor)
          @destroy_later << @professor3 = FactoryBot.create(:professor)

          @destroy_later << FactoryBot.create(:advisement_authorization, professor: @professor1, level: @level1)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: @professor2, level: @level2)

          @destroy_later << enrollment1 = FactoryBot.create(:enrollment, level: @level1)
          @destroy_later << enrollment2 = FactoryBot.create(:enrollment, level: @level2)

          @destroy_later << FactoryBot.create(:advisement, professor: @professor1, enrollment: enrollment1)
          @destroy_later << FactoryBot.create(:advisement, professor: @professor1, enrollment: enrollment2, main_advisor: false)
          @destroy_later << FactoryBot.create(:advisement, professor: @professor2, enrollment: enrollment2)
          @destroy_later << FactoryBot.create(:advisement, professor: @professor3, enrollment: enrollment1, main_advisor: false)
          @destroy_later << FactoryBot.create(:advisement, professor: @professor3, enrollment: enrollment2, main_advisor: false)
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
          @destroy_later << enrollment = FactoryBot.create(:enrollment)
          expect(professor.advisement_point(enrollment)).to eql(0.0)
        end
        it "the enrollment is not advised by the professor" do
          @destroy_later << professor = FactoryBot.create(:professor)
          @destroy_later << other_professor = FactoryBot.create(:professor)
          @destroy_later << enrollment = FactoryBot.create(:enrollment)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: other_professor, level: enrollment.level)
          @destroy_later << FactoryBot.create(:advisement, professor: other_professor, enrollment: enrollment)

          expect(professor.advisement_point(enrollment)).to eql(0.0)
        end
        it "the enrollment have a dismissal" do
          @destroy_later << professor = FactoryBot.create(:professor)
          @destroy_later << enrollment = FactoryBot.create(:enrollment)
          @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)
          @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
          @destroy_later << FactoryBot.create(:dismissal, enrollment: enrollment)

          expect(professor.advisement_point(enrollment)).to eql(0.0)
        end
      end
      it "should return 1 when the professor is the only authorized advisor (default)" do
        @destroy_later << professor = FactoryBot.create(:professor)
        @destroy_later << other_professor = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)

        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
        @destroy_later << FactoryBot.create(:advisement, professor: other_professor, enrollment: enrollment, main_advisor: false)

        expect(professor.advisement_point(enrollment)).to eql(1.0)
      end

      it "should return the configured value when the professor is the only authorized advisor" do
        config = CustomVariable.find_by_variable(:single_advisor_points)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :single_advisor_points, value: "2.0")

        @destroy_later << professor = FactoryBot.create(:professor)
        @destroy_later << other_professor = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)

        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
        @destroy_later << FactoryBot.create(:advisement, professor: other_professor, enrollment: enrollment, main_advisor: false)

        expect(professor.advisement_point(enrollment)).to eql(2.0)
      end

      it "should return 0.5 when the professor is not the only authorized advisor (default)" do
        @destroy_later << professor = FactoryBot.create(:professor)
        @destroy_later << other_professor = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)

        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: other_professor, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
        @destroy_later << FactoryBot.create(:advisement, professor: other_professor, enrollment: enrollment, main_advisor: false)

        expect(professor.advisement_point(enrollment)).to eql(0.5)
      end

      it "should return the configured value when the professor is not the only authorized advisor" do
        config = CustomVariable.find_by_variable(:multiple_advisor_points)
        config.delete unless config.nil?
        @destroy_later << CustomVariable.create(variable: :multiple_advisor_points, value: "1.0")

        @destroy_later << professor = FactoryBot.create(:professor)
        @destroy_later << other_professor = FactoryBot.create(:professor)
        @destroy_later << enrollment = FactoryBot.create(:enrollment)

        @destroy_later << FactoryBot.create(:advisement_authorization, professor: professor, level: enrollment.level)
        @destroy_later << FactoryBot.create(:advisement_authorization, professor: other_professor, level: enrollment.level)

        @destroy_later << FactoryBot.create(:advisement, professor: professor, enrollment: enrollment)
        @destroy_later << FactoryBot.create(:advisement, professor: other_professor, enrollment: enrollment, main_advisor: false)

        expect(professor.advisement_point(enrollment)).to eql(1.0)
      end
    end
  end
end
