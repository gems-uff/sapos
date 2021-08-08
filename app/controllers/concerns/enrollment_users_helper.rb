# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module EnrollmentUsersHelper extend ActiveSupport::Concern

  def enrollments_that_should_have_user(enrollments, result=nil, &block)
    result = [] if result.nil?
    found = false
    enrollments.each do |enrollment|
      block.call(enrollment) if block_given?
      if enrollment.should_have_user?
        result << enrollment
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
    student_enrollments = enrollments_to_students_map(enrollments)
    counts = {}
    counts[:enrollments] = enrollments.count
    counts[:students] = student_enrollments.size
    counts[:existingstudents] = 0
    counts[:noemail] = 0
     
    new_students = []
    new_students_force = []
    student_enrollments.each do |student, enrollments|
      counts[:noemail] += 1 unless student.has_email?
      counts[:existingstudents] += 1 if student.has_user?
      if ! enrollments_that_should_have_user(enrollments, new_students)[:found]
        enrollments_that_should_have_user(enrollments, new_students_force) do |enrollment|
          enrollment.force_new_user = true
        end
      end
    end
    counts[:default] = new_students.count
    counts[:force] = counts[:default] + new_students_force.count
    counts
  end

  def create_enrollments_users(enrollments, force_new)
    created = 0
    enrollments.each do |enrollment|
      enrollment.force_new_user = force_new
      created += 1 if enrollment.create_user!
    end
    created
  end


end