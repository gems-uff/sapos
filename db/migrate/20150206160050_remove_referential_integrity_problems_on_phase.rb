class RemoveReferentialIntegrityProblemsOnPhase < ActiveRecord::Migration
  def up
  	PhaseCompletion.joins(:phase).where(Phase.arel_table[:name].eq(nil)).destroy_all
  end

  def down
  end
end
