class UpdateAllEndDateAndCancelDateOfScholarshipAndScholarshipDuration < ActiveRecord::Migration
  def up
  	Scholarship.all.each do |scholarship|
  	  puts "Scholarship #{scholarship.id}"
      scholarship.save!
  	end
  	ScholarshipDuration.all.each do |scholarship_duration|
  	  puts "ScholarshipDuration #{scholarship_duration.id}"
      scholarship_duration.save!
  	end
  end

  def down
  end
end
