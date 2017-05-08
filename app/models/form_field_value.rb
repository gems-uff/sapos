class FormFieldValue < ActiveRecord::Base
  belongs_to :form_field

  validates :value, presence: true

end
