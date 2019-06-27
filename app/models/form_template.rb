class FormTemplate < ApplicationRecord
  has_and_belongs_to_many  :form_image

  validates :name, :presence => true

end
