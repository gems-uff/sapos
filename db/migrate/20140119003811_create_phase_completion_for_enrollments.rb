class CreatePhaseCompletionForEnrollments < ActiveRecord::Migration
  def up
  	Enrollment.all.each do |enrollment|
  	  puts enrollment.id
  	  enrollment.save!
  	end
  end

  def down
  end
end
