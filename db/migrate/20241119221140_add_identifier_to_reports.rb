# frozen_string_literal: true

class AddIdentifierToReports < ActiveRecord::Migration[7.0]
  def change
    add_column :reports, :identifier, :string
  end
end
