class AddIsLanguageToPhases < ActiveRecord::Migration
  def change
    add_column :phases, :is_language, :boolean, default: false
  end
end
