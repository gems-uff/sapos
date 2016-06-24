class ApplicationProcess < ActiveRecord::Base
  has_many :student_applications, :dependent => :restrict_with_exception

  belongs_to :form_template, :class_name => 'FormTemplate', :foreign_key => 'form_template_id'
  belongs_to :letter_template, :class_name => 'FormTemplate',:foreign_key => 'letter_template_id'
end
