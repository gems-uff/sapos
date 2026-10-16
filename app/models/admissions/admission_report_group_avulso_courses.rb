# frozen_string_literal: true

class Admissions::AdmissionReportGroupAvulsoCourses < Admissions::AdmissionReportGroupBase
  def prepare_config
    @sections << {
      title: Admissions::AdmissionReportGroup::AVULSO_COURSES,
      columns: [
        { header: avulso_columns_t(:course), mode: :avulso_course },
        { header: avulso_columns_t(:period), mode: :avulso_period },
        { header: avulso_columns_t(:grade), mode: :avulso_grade }
      ]
    }
  end

  def application_sections(application, &block)
    return if @sections.empty?
    section = @sections[0]
    class_enrollments = avulso_class_enrollments(application)
    section[:application_columns] = section[:columns].map do |column|
      {
        value: format_value(column[:mode], class_enrollments),
        column: column
      }
    end
  end

  private
    def avulso_columns_t(key, **args)
      key = "activerecord.attributes.admissions/admission_report_group.avulso_columns.#{key}"
      I18n.t(key, **args)
    end

    def avulso_class_enrollments(application)
      students = application.students_by_cpf
      return ClassEnrollment.none if students.blank?
      status_name = CustomVariable.avulso_enrollment_status_name
      enrollment_ids = Enrollment
        .where(student_id: students.map(&:id))
        .joins(:enrollment_status)
        .where(enrollment_statuses: { name: status_name })
        .pluck(:id)
      return ClassEnrollment.none if enrollment_ids.blank?
      ClassEnrollment.where(enrollment_id: enrollment_ids).includes(course_class: :course)
    end

    def format_value(mode, class_enrollments)
      return "" if class_enrollments.blank?
      values = class_enrollments.map do |class_enrollments|
        course_class = class_enrollments.course_class
        case mode
        when :avulso_course
          course_class.course.name
        when :avulso_period
          "#{course_class.year}/#{course_class.semester}"
        when :avulso_grade
          grade = class_enrollments.grade_to_view
          grade.nil? ? "-" : grade.to_s
        end
      end
      values.join("; ")
    end
end
