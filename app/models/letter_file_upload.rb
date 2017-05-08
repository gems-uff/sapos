class LetterFileUpload < ActiveRecord::Base
  mount_uploader :file, FormFileUploader
  belongs_to :letter_request
  belongs_to :form_field
end
