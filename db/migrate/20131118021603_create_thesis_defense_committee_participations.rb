class CreateThesisDefenseCommitteeParticipations < ActiveRecord::Migration
  def change
    create_table :thesis_defense_committee_participations do |t|
      t.references :professor
      t.references :enrollment

      t.timestamps
    end
    add_index :thesis_defense_committee_participations, :professor_id
    add_index :thesis_defense_committee_participations, :enrollment_id
  end
end
