# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admissions::AdmissionReportGroupAvulsoCourses, type: :model do
  COURSE_HEADER = I18n.t("activerecord.attributes.admissions/admission_report_group.avulso_columns.course")
  PERIOD_HEADER = I18n.t("activerecord.attributes.admissions/admission_report_group.avulso_columns.period")
  GRADE_HEADER = I18n.t("activerecord.attributes.admissions/admission_report_group.avulso_columns.grade")

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

  let(:report_group) do
    config = double("admission_report_config", group_column_tabular: nil)
    Admissions::AdmissionReportGroupAvulsoCourses.new(config, nil, nil, [], nil)
  end

  # application dublê: evita montar FilledForm/FormField só pra achar o CPF,
  # já que o cruzamento por CPF em si é testado em admission_application_spec.
  def application_with_students(students)
    double("admission_application", students_by_cpf: students)
  end

  # simula grade_to_view por id, porque avulso_class_enrollments recarrega os
  # registros do banco, então a instância criada aqui não é a mesma que chega
  # no format_value.
  def stub_grades(grades_by_class_enrollment_id)
    allow_any_instance_of(ClassEnrollment).to receive(:grade_to_view) do |instance|
      grades_by_class_enrollment_id[instance.id]
    end
  end

  def build_class_enrollment(course_name:, year:, semester:, status:)
    course = FactoryBot.create(:course, name: course_name)
    course_class = FactoryBot.create(:course_class, course: course, year: year, semester: semester)
    enrollment = FactoryBot.create(:enrollment, enrollment_status: status)
    FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)
  end

  def run_sections_for(application)
    report_group.prepare_config
    report_group.application_sections(application)
    report_group.sections[0][:application_columns]
  end

  def values_for(columns, header)
    columns.find { |c| c[:column][:header] == header }[:value]
  end

  describe "prepare_config" do
    it "builds one section with the three avulso columns" do
      report_group.prepare_config
      expect(report_group.sections.size).to eq(1)
      headers = report_group.sections[0][:columns].map { |c| c[:header] }
      expect(headers).to eq([COURSE_HEADER, PERIOD_HEADER, GRADE_HEADER])
    end
  end

  describe "application_sections" do
    context "when the student has no CPF match" do
      it "returns blank values for all columns" do
        application = application_with_students(Student.none)
        columns = run_sections_for(application)
        expect(values_for(columns, COURSE_HEADER)).to eq("")
        expect(values_for(columns, PERIOD_HEADER)).to eq("")
        expect(values_for(columns, GRADE_HEADER)).to eq("")
      end
    end

    context "when the matched student has no 'Avulso' enrollment" do
      it "returns blank values for all columns" do
        student = FactoryBot.create(:student)
        build_class_enrollment(
          course_name: "Regular Course", year: "2027", semester: "1", status: @regular_status
        )
        application = application_with_students([student])
        columns = run_sections_for(application)
        expect(values_for(columns, COURSE_HEADER)).to eq("")
        expect(values_for(columns, PERIOD_HEADER)).to eq("")
        expect(values_for(columns, GRADE_HEADER)).to eq("")
      end
    end

    context "when there is a single avulso class enrollment with a grade" do
      it "aligns course, period and grade correctly" do
        student = FactoryBot.create(:student)
        enrollment = FactoryBot.create(:enrollment, student: student, enrollment_status: @avulso_status)
        course = FactoryBot.create(:course, name: "Tem nota")
        course_class = FactoryBot.create(:course_class, course: course, year: "2027", semester: "1")
        class_enrollment = FactoryBot.create(:class_enrollment, course_class: course_class, enrollment: enrollment)

        stub_grades({ class_enrollment.id => 10 })
        application = application_with_students([student])

        columns = run_sections_for(application)
        expect(values_for(columns, COURSE_HEADER)).to eq("Tem nota")
        expect(values_for(columns, PERIOD_HEADER)).to eq("2027/1")
        expect(values_for(columns, GRADE_HEADER)).to eq("10")
      end
    end

    context "when there is a mix of graded and ungraded avulso enrollments" do
      # Este é o caso do bug: sem placeholder para nota ausente, a lista de
      # notas fica mais curta que a de disciplinas e desalinha o índice.
      it "keeps the same number of items and the same order across all three columns" do
        student = FactoryBot.create(:student)
        graded_ce = build_class_enrollment(
          course_name: "Tem nota", year: "2027", semester: "1", status: @avulso_status
        )
        graded_ce.enrollment.update!(student: student)
        ungraded_ce = build_class_enrollment(
          course_name: "Sem nota", year: "2027", semester: "1", status: @avulso_status
        )
        ungraded_ce.enrollment.update!(student: student)

        stub_grades({ graded_ce.id => 10, ungraded_ce.id => nil })
        application = application_with_students([student])

        columns = run_sections_for(application)
        courses = values_for(columns, COURSE_HEADER).split("; ")
        periods = values_for(columns, PERIOD_HEADER).split("; ")
        grades = values_for(columns, GRADE_HEADER).split("; ")

        expect(courses.size).to eq(2)
        expect(periods.size).to eq(2)
        expect(grades.size).to eq(2)

        # reconstrói o mapeamento curso -> nota pela posição, e confirma que
        # cada disciplina ficou com a nota certa, não com a do vizinho.
        mapping = courses.zip(grades).to_h
        expect(mapping["Tem nota"]).to eq("10")
        expect(mapping["Sem nota"]).to eq("-")
      end
    end

    context "when there are multiple avulso enrollments all with grades" do
      it "joins all values in the same relative order" do
        student = FactoryBot.create(:student)
        ce1 = build_class_enrollment(
          course_name: "Curso A", year: "2027", semester: "1", status: @avulso_status
        )
        ce1.enrollment.update!(student: student)
        ce2 = build_class_enrollment(
          course_name: "Curso B", year: "2027", semester: "2", status: @avulso_status
        )
        ce2.enrollment.update!(student: student)

        stub_grades({ ce1.id => 7, ce2.id => 9 })
        application = application_with_students([student])

        columns = run_sections_for(application)
        courses = values_for(columns, COURSE_HEADER).split("; ")
        periods = values_for(columns, PERIOD_HEADER).split("; ")
        grades = values_for(columns, GRADE_HEADER).split("; ")

        mapping = courses.zip(periods, grades).map { |c, p, g| [c, [p, g]] }.to_h
        expect(mapping["Curso A"]).to eq(["2027/1", "7"])
        expect(mapping["Curso B"]).to eq(["2027/2", "9"])
      end
    end

    context "when there are multiple avulso enrollments all without grades" do
      it "fills every grade slot with the placeholder" do
        student = FactoryBot.create(:student)
        ce1 = build_class_enrollment(
          course_name: "Curso A", year: "2027", semester: "1", status: @avulso_status
        )
        ce1.enrollment.update!(student: student)
        ce2 = build_class_enrollment(
          course_name: "Curso B", year: "2027", semester: "2", status: @avulso_status
        )
        ce2.enrollment.update!(student: student)

        stub_grades({ ce1.id => nil, ce2.id => nil })
        application = application_with_students([student])

        columns = run_sections_for(application)
        grades = values_for(columns, GRADE_HEADER).split("; ")
        expect(grades).to eq(["-", "-"])
      end
    end

    context "when students_by_cpf matches more than one student" do
      it "considers avulso enrollments from every matched student" do
        student1 = FactoryBot.create(:student)
        student2 = FactoryBot.create(:student)
        ce1 = build_class_enrollment(
          course_name: "Curso A", year: "2027", semester: "1", status: @avulso_status
        )
        ce1.enrollment.update!(student: student1)
        ce2 = build_class_enrollment(
          course_name: "Curso B", year: "2027", semester: "1", status: @avulso_status
        )
        ce2.enrollment.update!(student: student2)

        stub_grades({ ce1.id => 5, ce2.id => 6 })
        application = application_with_students([student1, student2])

        columns = run_sections_for(application)
        courses = values_for(columns, COURSE_HEADER).split("; ")
        expect(courses).to contain_exactly("Curso A", "Curso B")
      end
    end
  end
    describe "prepare_group_row across multiple applications (same report_group instance)" do
    def row_value(row, header)
      row.find { |c| c[:column][:header] == header }[:value]
    end
 
    it "does not leak one candidate's disciplines into another candidate's row" do
      student_a = FactoryBot.create(:student)
      ce_a = build_class_enrollment(
        course_name: "Curso do A", year: "2027", semester: "1", status: @avulso_status
      )
      ce_a.enrollment.update!(student: student_a)
      stub_grades({ ce_a.id => 8 })
      application_a = application_with_students([student_a])
 
      student_b = FactoryBot.create(:student)
      ce_b = build_class_enrollment(
        course_name: "Curso do B", year: "2027", semester: "2", status: @avulso_status
      )
      ce_b.enrollment.update!(student: student_b)
      stub_grades({ ce_a.id => 8, ce_b.id => 4 })
      application_b = application_with_students([student_b])
 
      report_group.prepare_config
 
      row_a = report_group.prepare_group_row(application_a)
      row_b = report_group.prepare_group_row(application_b)
 
      expect(row_value(row_a, COURSE_HEADER)).to eq("Curso do A")
      expect(row_value(row_a, GRADE_HEADER)).to eq("8")
      expect(row_value(row_b, COURSE_HEADER)).to eq("Curso do B")
      expect(row_value(row_b, GRADE_HEADER)).to eq("4")
    end
 
    it "keeps the first candidate's already-captured row unchanged after processing the second candidate" do
      student_a = FactoryBot.create(:student)
      ce_a = build_class_enrollment(
        course_name: "Curso do A", year: "2027", semester: "1", status: @avulso_status
      )
      ce_a.enrollment.update!(student: student_a)
 
      student_b = FactoryBot.create(:student)
      ce_b = build_class_enrollment(
        course_name: "Curso do B", year: "2027", semester: "2", status: @avulso_status
      )
      ce_b.enrollment.update!(student: student_b)
 
      stub_grades({ ce_a.id => 8, ce_b.id => 4 })
 
      report_group.prepare_config
 
      row_a = report_group.prepare_group_row(application_with_students([student_a]))
      row_a_course_snapshot = row_value(row_a, COURSE_HEADER)
      row_a_grade_snapshot = row_value(row_a, GRADE_HEADER)
 
      # processa o segundo candidato DEPOIS de já ter capturado a linha do
      # primeiro, como o gerador de relatório faz linha a linha
      report_group.prepare_group_row(application_with_students([student_b]))
 
      expect(row_value(row_a, COURSE_HEADER)).to eq(row_a_course_snapshot)
      expect(row_value(row_a, GRADE_HEADER)).to eq(row_a_grade_snapshot)
      expect(row_value(row_a, COURSE_HEADER)).to eq("Curso do A")
      expect(row_value(row_a, GRADE_HEADER)).to eq("8")
    end
 
    it "does not accumulate disciplines from a previous candidate for one with no avulso enrollments" do
      student_a = FactoryBot.create(:student)
      ce_a = build_class_enrollment(
        course_name: "Curso do A", year: "2027", semester: "1", status: @avulso_status
      )
      ce_a.enrollment.update!(student: student_a)
      stub_grades({ ce_a.id => 8 })
 
      student_b = FactoryBot.create(:student) # sem nenhuma matrícula avulso
 
      report_group.prepare_config
 
      report_group.prepare_group_row(application_with_students([student_a]))
      row_b = report_group.prepare_group_row(application_with_students([student_b]))
 
      expect(row_value(row_b, COURSE_HEADER)).to eq("")
      expect(row_value(row_b, PERIOD_HEADER)).to eq("")
      expect(row_value(row_b, GRADE_HEADER)).to eq("")
    end
  end

end