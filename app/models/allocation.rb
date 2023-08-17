# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a CourseClass Allocation time slot
class Allocation < ApplicationRecord
  has_paper_trail

  belongs_to :course_class, optional: false

  validates :day,
    inclusion: { in: I18n.translate("date.day_names") },
    presence: true
  validates :course_class, presence: true
  validates :start_time,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
  validates :end_time,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 23 }
  validate :start_end_time_validation
  validate :scheduling_conflict_validation

  def to_label
    name_l = self.course_class.name || self.course_class.course.name
    time_l = "#{self.start_time}:00 - #{self.end_time}:00"
    room_t = I18n.t("activerecord.attributes.allocation.room")
    room_l = self.room ? "- #{room_t} : #{self.room}" : ""
    "#{name_l} - #{self.day}, #{time_l} #{room_l}"
  end

  def to_shortlabel
    "#{self.start_time}-#{self.end_time}\n#{self.room || ' '}"
  end

  def intersects(other)
    return nil if self.day != other.day
    return :start_time if
      other.start_time <= self.start_time &&
      self.start_time < other.end_time
    return :end_time if
      other.start_time < self.end_time &&
      self.end_time <= other.end_time
    nil
  end

  private
    def start_end_time_validation
      return if self.start_time.blank?
      return if self.end_time.blank?
      return if self.end_time > self.start_time
      errors.add(:start_time, :end_time_before_start_time)
    end

    def scheduling_conflict_validation
      return if self.start_time.blank?
      return if self.end_time.blank?
      allocations = Allocation.where(
        course_class_id: self.course_class,
        day: self.day
      )
      return if allocations.blank?

      allocations.each do |allocation|
        next if allocation.id == self.id
        intersection = self.intersects(allocation)
        next if intersection.nil?
        errors.add(intersection, :scheduling_conflict)
        break
      end
    end
end
