class AddResearchLineToEnrollment < ActiveRecord::Migration[7.0]
  def up
    add_reference :enrollments, :research_line, null: true, foreign_key: { on_delete: :nullify }
  end

  def down
    remove_reference :enrollments, :research_line
  end
end
