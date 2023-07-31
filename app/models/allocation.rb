# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a CourseClass Allocation time slot
class Allocation < ApplicationRecord
  has_paper_trail

  belongs_to :course_class, optional: false

  validates :day, inclusion: { in: I18n.translate("date.day_names") }, presence: true
  validates :course_class, presence: true
  validates :start_time, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
  validates :end_time, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
  validate :start_end_time_validation
  validate :scheduling_conflict_validation

  def to_label
    "#{self.course_class.name || self.course_class.course.name} - #{self.day},
      #{self.start_time}:00 - #{self.end_time}:00 #{"- #{I18n.t("activerecord.attributes.allocation.room")} : #{self.room}" if self.room }"
  end

  def intersects(other)
    return nil if self.day != other.day
    return :start_time if other.start_time <= self.start_time && self.start_time < other.end_time
    return :end_time if other.start_time < self.end_time && self.end_time <= other.end_time
    nil
  end

  private
    def start_end_time_validation
      if !self.start_time.blank? && !self.end_time.blank? && self.end_time <= self.start_time
        errors.add(:start_time, :end_time_before_start_time)
      end
    end

    def scheduling_conflict_validation
      allocations = Allocation.where(course_class_id: self.course_class, day: self.day)

      if allocations && !self.start_time.blank? && !self.end_time.blank?
        allocations.each do |allocation|
          if allocation.id != self.id
            intersection = self.intersects(allocation)
            unless intersection.nil?
              errors.add(intersection, :scheduling_conflict)
              break
            end
          end
        end
      end
    end
end
