# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentUsersHelper extend ActiveSupport::Concern

  def append_first_selection(collection, result=nil, &block)
    result = [] if result.nil?
    found = false
    collection.each do |item|
      if block.call(item)
        result << item
        found = true
        break
      end
    end
    {found: found, result: result}
  end

  def enrollments_to_students_map(enrollments)
    student_enrollments = {} 
    enrollments.each do |enrollment|
      student = enrollment.student
      if ! student_enrollments.key? student
        student_enrollments[student] = []
      end
      student_enrollments[student] << enrollment
    end
    student_enrollments
  end

  def new_users_count(enrollments)
    counts = {}
    counts[:enrollments] = enrollments.count
    allowed_enrollments = enrollments.select { |e| e.enrollment_status.user }
    counts[:allowedenrollments] = allowed_enrollments.count
    student_enrollments = enrollments_to_students_map(allowed_enrollments)
    counts[:students] = student_enrollments.size
    counts[:existingstudents] = 0
    counts[:noemail] = 0
    new_students = []
    new_students_dismissed = []
    new_students_all = []

    student_enrollments.each do |student, enrollments|    
      counts[:noemail] += 1 unless student.has_email?
      counts[:existingstudents] += 1 if student.has_user?
      if student.can_have_new_user?
        new_students_all << enrollments[0]
        append_first_selection(enrollments, new_students) { |e| e.dismissal.nil? }
        append_first_selection(enrollments, new_students_dismissed) { |e| ! e.dismissal.nil? }
      end
    end
    counts[:default] = new_students.count
    counts[:dismissed] = new_students_dismissed.count
    counts[:all] = new_students_all.count
    counts
  end

  def create_enrollments_users(enrollments, mode)
    created = 0
    enrollments.each do |enrollment|
      enrollment.new_user_mode = mode
      created += 1 if enrollment.create_user!
    end
    created
  end


end