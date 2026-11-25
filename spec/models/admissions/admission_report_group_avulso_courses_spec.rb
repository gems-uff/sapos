# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionReportGroupAvulsoCourses, type: :model do
  HEADER_KEY = "activerecord.attributes.admissions/admission_report_group.avulso_columns.courses"
  COURSES_HEADER = I18n.t(HEADER_KEY)

  before(:all) do
    @avulso_status = FactoryBot.create(:enrollment_status, name: "Avulso")
    @regular_status = FactoryBot.create(:enrollment_status, name: "Regular")
  end

  after(:all) do
    @avulso_status.delete
    @regular_status.delete
  end

  after(:each) do
    ClassEnrollment.delete_all
    Enrollment.delete_all
    CourseClass.delete_all
    Course.delete_all
    Student.delete_all
  end

  let(:student) { FactoryBot.create(:student) }

  def build_group(applications: [], hide_empty_sections: false)
    config = double(
      "admission_report_config", group_column_tabular: nil, hide_empty_sections:
    )
    described_class.new(config, nil, nil, applications, nil)
  end

  # A busca por CPF/e-mail é testada em admission_application_spec
  def application_with(students)
    double("admission_application", students:)
  end

  # grade_to_view por id: a consulta recarrega os registros do banco
  def stub_grades(grades_by_class_enrollment_id)
    allow_any_instance_of(ClassEnrollment).to receive(:grade_to_view) do |instance|
      grades_by_class_enrollment_id[instance.id]
    end
  end

  def build_class_enrollment(course_name:, year:, semester:, student:, status: @avulso_status)
    course = FactoryBot.create(:course, name: course_name)
    course_class = FactoryBot.create(:course_class, course:, year:, semester:)
    enrollment = FactoryBot.create(:enrollment, student:, enrollment_status: status)
    FactoryBot.create(:class_enrollment, course_class:, enrollment:)
  end

  def courses_value(application, group: build_group)
    group.prepare_config
    group.application_sections(application)
    group.sections[0][:application_columns].first[:value]
  end

  it "has a translated header" do
    expect(I18n.exists?(HEADER_KEY)).to be(true)
  end

  describe "prepare_config" do
    it "builds one section with a single column" do
      group = build_group
      group.prepare_config
      expect(group.sections.size).to eq(1)
      expect(group.sections[0][:columns].map { |c| c[:header] }).to eq([COURSES_HEADER])
    end

    it "is hidden when nobody matches and empty sections are hidden" do
      group = build_group(applications: [application_with({})], hide_empty_sections: true)
      group.prepare_config
      expect(group.sections).to be_empty
    end

    it "is kept when someone matches and empty sections are hidden" do
      group = build_group(
        applications: [application_with({}), application_with({ cpf: [student] })],
        hide_empty_sections: true
      )
      group.prepare_config
      expect(group.sections.size).to eq(1)
    end
  end

  describe "application_sections" do
    it "leaves the cell blank, keeping the columns aligned, without a student" do
      group = build_group
      group.prepare_config
      row = group.prepare_group_row(application_with({}))
      expect(row.size).to eq(group.header.size)
      expect(row.first[:value]).to eq("")
    end

    it "finds a student matched only by e-mail" do
      ce = build_class_enrollment(course_name: "Curso A", year: "2027", semester: "1", student:)
      stub_grades({ ce.id => 7 })
      expect(courses_value(application_with({ email: [student] }))).to eq("Curso A (2027/1): 7")
    end

    it "formats course, period and grade, with comma as decimal separator" do
      ce = build_class_enrollment(course_name: "Curso A", year: "2027", semester: "1", student:)
      stub_grades({ ce.id => 9.5 })
      expect(courses_value(application_with({ cpf: [student] }))).to eq("Curso A (2027/1): 9,5")
    end

    it "uses the placeholder when there is no grade" do
      ce = build_class_enrollment(course_name: "Curso A", year: "2027", semester: "1", student:)
      stub_grades({ ce.id => nil })
      expect(courses_value(application_with({ cpf: [student] }))).to eq("Curso A (2027/1): -")
    end

    it "includes avulso and regular enrollments" do
      ce1 = build_class_enrollment(
        course_name: "Curso A", year: "2027", semester: "1", student:, status: @avulso_status
      )
      ce2 = build_class_enrollment(
        course_name: "Curso B", year: "2026", semester: "2", student:, status: @regular_status
      )
      stub_grades({ ce1.id => 8, ce2.id => 6 })
      expect(courses_value(application_with({ cpf: [student] })))
        .to eq("Curso A (2027/1): 8; Curso B (2026/2): 6")
    end

    it "includes the courses of every enrollment of the student" do
      ce1 = build_class_enrollment(course_name: "Curso A", year: "2026", semester: "1", student:)
      ce2 = build_class_enrollment(course_name: "Curso B", year: "2026", semester: "2", student:)
      stub_grades({ ce1.id => 5, ce2.id => 6 })
      expect(courses_value(application_with({ cpf: [student] })))
        .to eq("Curso B (2026/2): 6; Curso A (2026/1): 5")
    end

    it "includes every Student found for the candidate" do
      other = FactoryBot.create(:student)
      ce1 = build_class_enrollment(course_name: "Curso A", year: "2027", semester: "1", student:)
      ce2 = build_class_enrollment(course_name: "Curso B", year: "2026", semester: "1", student: other)
      stub_grades({ ce1.id => 5, ce2.id => 6 })
      application = application_with({ cpf: [student], email: [other] })
      expect(courses_value(application)).to eq("Curso A (2027/1): 5; Curso B (2026/1): 6")
    end

    it "orders by period, most recent first" do
      ce_old = build_class_enrollment(course_name: "Curso A", year: "2026", semester: "2", student:)
      ce_new = build_class_enrollment(course_name: "Curso B", year: "2027", semester: "1", student:)
      stub_grades({ ce_old.id => 8, ce_new.id => 9 })
      expect(courses_value(application_with({ cpf: [student] })))
        .to eq("Curso B (2027/1): 9; Curso A (2026/2): 8")
    end

    it "shows a grade released after the application" do
      ce = build_class_enrollment(course_name: "Curso A", year: "2027", semester: "1", student:)
      application = application_with({ cpf: [student] })
      group = build_group
      stub_grades({ ce.id => nil })
      expect(courses_value(application, group:)).to eq("Curso A (2027/1): -")
      stub_grades({ ce.id => 10 })
      group.application_sections(application)
      expect(group.sections[0][:application_columns].first[:value]).to eq("Curso A (2027/1): 10")
    end

    it "does not leak one candidate's courses into another's row" do
      other = FactoryBot.create(:student)
      ce_a = build_class_enrollment(course_name: "Curso A", year: "2027", semester: "1", student:)
      ce_b = build_class_enrollment(course_name: "Curso B", year: "2027", semester: "2", student: other)
      stub_grades({ ce_a.id => 8, ce_b.id => 4 })
      group = build_group
      group.prepare_config
      row_a = group.prepare_group_row(application_with({ cpf: [student] }))
      row_b = group.prepare_group_row(application_with({ cpf: [other] }))
      expect(row_a.first[:value]).to eq("Curso A (2027/1): 8")
      expect(row_b.first[:value]).to eq("Curso B (2027/2): 4")
    end
  end
end
