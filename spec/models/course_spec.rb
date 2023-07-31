# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Course, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:course_research_areas).dependent(:destroy) }
  it { should have_many(:course_classes).dependent(:restrict_with_exception) }
  it { should have_many(:research_areas).through(:course_research_areas) }

  before(:all) do
    @destroy_later = []
  end
  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  let(:course_type) { FactoryBot.build(:course_type) }
  let(:course) do
    Course.new(
      course_type: course_type,
      name: "Disciplina",
      code: "Abc",
      credits: 10,
      workload: 68
    )
  end
  subject { course }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:course_type).required(true) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:code) }
    it { should validate_presence_of(:code) }
    it { should validate_presence_of(:credits) }
    it { should validate_presence_of(:workload) }

    describe "name" do
      context "should have error taken when" do
        it "name of available course is already in use" do
          name = "Course"
          @destroy_later << FactoryBot.create(:course, name: name, available: true)
          course.name = name
          expect(course).to have_error(:check_unique_name_for_available_courses).on :name
        end
      end
    end
  end
  describe "Methods" do
    context "workload_value" do
      it "should return 0 when there is no workload" do
        course.workload = nil
        expect(course.workload_value).to eq(0)
      end

      it "should return 5 when workload is 5" do
        course.workload = 5
        expect(course.workload_value).to eq(5)
      end
    end

    context "workload_text" do
      it "should return N/A when there is no workload" do
        course.workload = nil
        expect(course.workload_text).to eq(I18n.translate("activerecord.attributes.course.empty_workload"))
      end

      it "should return 5h when workload is 5" do
        course.workload = 5
        expect(course.workload_text).to eq(I18n.translate("activerecord.attributes.course.workload_time", time: 5))
      end
    end
  end
end
