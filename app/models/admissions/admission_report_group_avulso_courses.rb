# frozen_string_literal: true

class Admissions::AdmissionReportGroupAvulsoCourses < Admissions::AdmissionReportGroupBase
  def prepare_config
    return if @config.hide_empty_sections &&
      @applications.none? { |application| students_for(application).present? }
    @sections << {
      title: Admissions::AdmissionReportGroup::AVULSO_COURSES,
      columns: [{ header: avulso_header, mode: :avulso_courses }]
    }
  end

  def application_sections(application, &block)
    return if @sections.empty?
    section = @sections[0]
    value = format_value(class_enrollments_for(application))
    section[:application_columns] = section[:columns].map do |column|
      { column:, value: }
    end
  end

  private
    def avulso_header
      I18n.t("activerecord.attributes.admissions/admission_report_group.avulso_columns.courses")
    end

    # Mesmo critério da tela de edição da candidatura: CPF ou e-mail
    def students_for(application)
      @students ||= {}.compare_by_identity
      @students[application] ||= application.students.values.flatten.uniq
    end

    def class_enrollments_for(application)
      students = students_for(application)
      return ClassEnrollment.none if students.blank?
      ClassEnrollment
        .joins(:enrollment)
        .where(enrollments: { student_id: students.map(&:id) })
        .eager_load(course_class: :course)
        .reorder("course_classes.year DESC, course_classes.semester DESC, courses.name")
    end

    def format_value(class_enrollments)
      return "" if class_enrollments.blank?
      class_enrollments.map do |ce|
        cc = ce.course_class
        "#{cc.course.name} (#{cc.year}/#{cc.semester}): #{format_grade(ce.grade_to_view)}"
      end.join("; ")
    end

    def format_grade(grade)
      grade.nil? ? "-" : grade.to_s.tr(".", ",")
    end
end
