class FixMaxLettersOnApplicationProcess < ActiveRecord::Migration
  def change
    rename_column :application_processes, :max_letter, :max_letters
  end
end
