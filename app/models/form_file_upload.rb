class FormFileUpload < ActiveRecord::Base
  mount_uploader :file, FormFileUploader
  belongs_to :student_application
  belongs_to :form_field
end
