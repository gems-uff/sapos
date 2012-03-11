class ScholarshipDuration < ActiveRecord::Base
  belongs_to :scholarship
  belongs_to :enrollment
        
  def to_label
    "#{start_date} - #{end_date}"
  end
      
  def last_scholarship_duration_end_date
    #we take care that the last scholarship duration found is not the same scholarship duration being edited
    return nil if scholarship.nil? or enrollment.nil?
    last_scholarship_duration = ScholarshipDuration.find :last, :conditions => ["scholarship_id = ? AND enrollment_id <> ?",scholarship.id,enrollment.id]
    last_scholarship_duration.end_date unless last_scholarship_duration.nil?    
  end
  
  def last_scholarship_duration_end_date_is_null
    l = last_scholarship_duration_end_date
    l.nil?
  end
  
  def scholarship_end_date
    finder_scholarship = Scholarship.find :last, :conditions => ["id = ?",scholarship]    
    finder_scholarship.end_date unless scholarship.nil?
  end
  
  def scholarship_start_date
    finder_scholarship = Scholarship.find :last, :conditions => ["id = ?",scholarship]
    finder_scholarship.start_date unless scholarship.nil?
  end   
           
  validates :scholarship, :presence => true
  validates :enrollment_id,  :presence => true, :uniqueness => {:scope => :scholarship_id ,:message => I18n.t("activerecord.errors.models.scholarship_duration.attributes.entollment_and_scholarship_uniqueness")} 
  
  #validates if scholarship isn't with another student
  validates_date :last_scholarship_duration_end_date, :on_or_before => :start_date, :unless => :last_scholarship_duration_end_date_is_null, :on_or_before_message => I18n.t("activerecord.errors.models.scholarship_duration.attributes.last_scholarship_duration_end_date")
#  
#  #validates if a scholarship duration start date isn't before it's end date
  validates_date :start_date, :on_or_before => :end_date, :on_or_before_message => I18n.t("activerecord.errors.models.scholarship_duration.attributes.start_date_after_end_date")
#  
#  #validates if a scholarship duration isn't invalid according to the selected scholarship    
  validates_date :start_date, :on_or_after  => :scholarship_start_date, :on_or_after_message  => I18n.t("activerecord.errors.models.scholarship_duration.attributes.start_date_before_scholarship_start_date")
  validates_date :start_date, :on_or_before => :scholarship_end_date,   :on_or_before_message => I18n.t("activerecord.errors.models.scholarship_duration.attributes.start_date_after_scholarship_end_date")
  validates_date :end_date,   :on_or_after  => :scholarship_start_date, :on_or_after_message  => I18n.t("activerecord.errors.models.scholarship_duration.attributes.end_date_before_scholarship_start_date")
  validates_date :end_date,   :on_or_before => :scholarship_end_date,   :on_or_before_message => I18n.t("activerecord.errors.models.scholarship_duration.attributes.end_date_after_scholarship_end_date")
#  
#  #validates if a cancel date of an scholarship duration is valid
  validates_date :cancel_date,:on_or_before => :end_date  , :allow_nil => true
  validates_date :cancel_date,:on_or_after  => :start_date, :allow_nil => true     
end
