# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ImportGradePreview < ApplicationRecord
  belongs_to :course_class
  belongs_to :user

  validates :token, presence: true, uniqueness: true

  # Um envio novo substitui a previa anterior do mesmo usuario na mesma turma
  def self.replace!(user:, course_class:, token:, payload:)
    transaction do
      where(user_id: user.id, course_class_id: course_class.id).delete_all
      create!(
        user: user, course_class: course_class, token: token,
        data: JSON.generate(payload)
      )
    end
  end

  def self.purge_expired
    where(created_at: ...CustomVariable.import_grades_session_timeout.ago).delete_all
  end

  def payload
    JSON.parse(data, symbolize_names: true)
  end

  def payload=(value)
    self.data = JSON.generate(value)
  end

  def expired?
    created_at < CustomVariable.import_grades_session_timeout.ago
  end

  def owned_by?(user, course_class)
    user_id == user.id && course_class_id == course_class.id
  end
end
