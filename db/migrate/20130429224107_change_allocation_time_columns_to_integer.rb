# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ChangeAllocationTimeColumnsToInteger < ActiveRecord::Migration[5.1]
  def self.up
    Allocation.transaction do
      allocations = Allocation.all.map { |allocation| {
        id: allocation.id,
        start_time: allocation.start_time.hour,
        end_time: allocation.end_time.hour
      } }
      change_column :allocations, :start_time, :integer
      change_column :allocations, :end_time, :integer
      Allocation.reset_column_information
      allocations.each do |allocation|
        allocation_for_update = Allocation.where(id: allocation[:id]).last
        allocation_for_update.update_attributes!(
          start_time: allocation[:start_time],
          end_time: allocation[:end_time]
        )
      end
    end
  end

  def self.down
    Allocation.transaction do
      allocations = Allocation.all.map { |allocation| {
        id: allocation.id,
        start_time: allocation.start_time,
        end_time: allocation.end_time
      } }
      change_column :allocations, :start_time, :time
      change_column :allocations, :end_time, :time

      Allocation.reset_column_information
      standard_date = Time.zone.parse("2000/01/01")
      allocations.each do |allocation|
        allocation_for_update = Allocation.where(id: allocation[:id]).last
        allocation_for_update.update_attributes!(
          start_time: (
            Time.zone.parse(standard_date.strftime("%Y/%m/%d")) +
            allocation[:start_time].hours
          ).to_datetime,
          end_time: (
            Time.zone.parse(standard_date.strftime("%Y/%m/%d")) +
            allocation[:end_time].hours
          )
        )
      end
    end
  end
end
