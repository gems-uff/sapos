class RemoveImpactFactorFromPapers < ActiveRecord::Migration[7.0]
  def change
    remove_column :papers, :impact_factor, :string
  end
end
