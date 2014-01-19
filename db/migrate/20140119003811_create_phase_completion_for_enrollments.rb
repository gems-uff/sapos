class CreatePhaseCompletionForEnrollments < ActiveRecord::Migration
  def up
  	Enrollment.all.each do |enrollment|
  	  enrollment.save!
  	end
  end

  def down
  end
end
