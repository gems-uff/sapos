class Professor < ActiveRecord::Base
  has_many :advisements, :dependent => :destroy
  has_many :enrollments, :through => :advisements
  has_many :scholarships, :dependent => :destroy

  validates :cpf, :presence => true, :uniqueness => true
  validates :name, :presence => true
  
#  It was considered that active advisements were enrollments without dismissals reasons
  def advisement_points
    search_sql = ["SELECT *
                  FROM  advisements AS a,
                      enrollments AS e
                  LEFT OUTER JOIN dismissals AS d
                  ON    d.enrollment_id = e.id
                  WHERE a.enrollment_id = e.id
                  AND   d.id IS NULL
                  AND   a.professor_id = ?",self.id]
    points = 0
    advisements = Advisement.find_by_sql(search_sql)
    advisements.each do |adv| 
      adv.main_advisor ? points += 1 : points += 0.5
    end
    
    "#{points}"
  end
end