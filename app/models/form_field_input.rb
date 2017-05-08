class FormFieldInput < ActiveRecord::Base
  belongs_to :student_application
  belongs_to :form_field
end
