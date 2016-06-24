class LetterTextInput < ActiveRecord::Base
  belongs_to :letter_request
  belongs_to :form_field
end
