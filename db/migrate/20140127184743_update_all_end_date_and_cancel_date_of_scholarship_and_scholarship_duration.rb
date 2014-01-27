class UpdateAllEndDateAndCancelDateOfScholarshipAndScholarshipDuration < ActiveRecord::Migration
  def up
  	Scholarship.all.each do |scholarship|
  	  scholarship.save!
  	end
  	ScholarshipDuration.all.each do |scholarship_duration|
  	  scholarship_duration.save!
  	end
  end

  def down
  end
end
