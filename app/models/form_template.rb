class FormTemplate < ActiveRecord::Base
  has_many :form_fields
  has_many :application_process_forms, :class_name =>ApplicationProcess, :foreign_key => :form_template_id
  has_many :application_process_letters, :class_name => ApplicationProcess, :foreign_key => :letter_template_id

  scope :letter, -> { where(is_letter: true) }
  scope :not_letter, -> { where(is_letter: false) }
  scope :enabled, -> { where(is_enabled: true) }

  accepts_nested_attributes_for :form_fields,
                                reject_if: :all_blank,
                                allow_destroy: true

  validates :name, presence: true

  def get_form_type
    if self.is_letter
      'Carta de Recomendação'
    else
      'Formulário'
    end
  end

end
