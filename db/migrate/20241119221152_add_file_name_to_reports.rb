# frozen_string_literal: true

class AddFileNameToReports < ActiveRecord::Migration[7.0]
  def change
    add_column :reports, :file_name, :string
  end
end
