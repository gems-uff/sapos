class AddThesisJudgementToDismissalReason < ActiveRecord::Migration
  def change
    add_column :dismissal_reasons, :thesis_judgement, :string
  end
end
