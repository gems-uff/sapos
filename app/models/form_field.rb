class FormField < ActiveRecord::Base
  belongs_to :form_template
  has_many :form_field_inputs
  has_many :form_text_inputs
  has_many :form_field_values
  has_many :letter_field_inputs
  has_many :letter_text_inputs
  has_many :form_file_uploads
  has_many :letter_file_uploads

  accepts_nested_attributes_for :form_field_values,
                                reject_if: :all_blank,
                                allow_destroy: true

  validates :name, presence: true

  def accept_mandatory? (t)
    if ['text', 'select', 'radio', 'string', 'file'].include? t
      true
    else
      false
    end
  end

  def allow_form_values? (t)
    if ['select', 'radio', 'collection_checkbox'].include? t
      true
    else
      false
    end
  end
end
