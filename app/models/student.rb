class Student < ActiveRecord::Base
  has_and_belongs_to_many :courses        
    
  belongs_to :birthplace, :foreign_key => "state_id", :class_name => "State"
  belongs_to :state
  
  belongs_to :country
  belongs_to :city
  
  #delete cascade for enrollment -- when a student is deleted, so are his enrollments
  has_many :enrollments, :dependent => :destroy  
   
  validates :name, :presence => true
  validates :cpf, :presence => true, :uniqueness => true
  
end
