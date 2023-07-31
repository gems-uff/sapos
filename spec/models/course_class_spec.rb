# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe CourseClass, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:class_enrollments).dependent(:destroy) }
  it { should have_many(:class_enrollment_requests).dependent(:destroy) }
  it { should have_many(:allocations).dependent(:destroy) }
  it { should have_many(:enrollments).through(:class_enrollments) }
  it { should have_many(:enrollment_requests).through(:class_enrollment_requests) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:course) { FactoryBot.build(:course) }
  let(:professor) { FactoryBot.build(:professor) }
  let(:course_class) do
    CourseClass.new(
      course: course,
      professor: professor,
      year: 2023,
      semester: 1
    )
  end
  subject { course_class }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:course).required(true) }
    it { should belong_to(:professor).required(true) }
    it { should validate_presence_of(:year) }
    it { should validate_presence_of(:semester) }
    it { should validate_inclusion_of(:semester).in_array(YearSemester::SEMESTERS) }

    # ToDo: find a way to test current_user in the model -- or change the model to not rely on it
    # describe "professor_changed_only_valid_fields" do
    #   it "should prevent professors from changing fields" do
    #     @destroy_later << role = FactoryBot.create(:role_professor)
    #     @destroy_later << user = FactoryBot.create(:user, role: role)
    #     user.confirmed_at = Time.zone.now
    #     user.save
    #     sign_in user
    #     course_class.year = 2022
    #     expect(scholarship).to have_error(:changes_to_disallowed_fields).on :course_class
    #   end
    # end
  end
  describe "Methods" do
    describe "to_label" do
      context "should return the expected string when" do
        it "name is not null and course type shows class name" do
          name = "name"
          other_name = "Other name"
          course_class.name = name
          course_class.year = 2013
          course_class.semester = YearSemester::SEMESTERS.first
          course_class.course = Course.new(name: other_name)
          @destroy_later << course_class.course.course_type = FactoryBot.create(:course_type, show_class_name: true)
          expect(course_class.to_label).to eql("#{other_name} (#{name}) - #{course_class.year}/#{course_class.semester}")
        end
        it "name is not null and course type doesnt show class name" do
          name = "name"
          other_name = "Other name"
          course_class.name = name
          course_class.year = 2013
          course_class.semester = YearSemester::SEMESTERS.first
          course_class.course = Course.new(name: other_name)
          @destroy_later << course_class.course.course_type = FactoryBot.create(:course_type, show_class_name: false)
          expect(course_class.to_label).to eql("#{other_name} - #{course_class.year}/#{course_class.semester}")
        end
        it "name is null" do
          course_name = "course_name"
          course_class.year = 2013
          course_class.semester = YearSemester::SEMESTERS.first
          course_class.course = Course.new(name: course_name)
          @destroy_later << course_class.course.course_type = FactoryBot.create(:course_type, show_class_name: true)
          expect(course_class.to_label).to eql("#{course_name} - #{course_class.year}/#{course_class.semester}")
        end
      end
    end

    describe "name_with_class_formated_to_reports" do
      context "course_class name, course name and obs_schedule has '<' characters" do
        it "replaces '<' characters with '&lt;'" do
          course_class.name = "class 4 < 5"
          course_class.course = Course.new(name: "course x < y")
          @destroy_later << course_class.course.course_type = FactoryBot.create(:course_type, show_class_name: true)
          course_class.obs_schedule = "w < z"
          expect(course_class.name_with_class_formated_to_reports).to eql("course x &lt; y (class 4 &lt; 5) - w &lt; z")
        end
      end
    end
  end
end
