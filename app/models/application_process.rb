class ApplicationProcess < ActiveRecord::Base
  has_many :student_applications, :dependent => :restrict_with_exception

  belongs_to :form_template, :class_name => 'FormTemplate', :foreign_key => 'form_template_id'
  belongs_to :letter_template, :class_name => 'FormTemplate',:foreign_key => 'letter_template_id'

  validates :min_letters, numericality: { only_integer: true, greater_than: -1, less_than: 100 }
  validates :max_letters, numericality: { only_integer: true, greater_than: -1, less_than: 100 }
  validates :semester, numericality: {only_integer: true, greater_than: 0, less_than: 3}
  validates :year, numericality: {only_integer: true, greater_than: 2000, less_than: 3000}
  validates :name, :semester, :year, :start_date, :end_date, :min_letters, :max_letters, presence: true

  validate :end_greater_than_start_date
  validate :max_greater_than_min_letters

  def end_greater_than_start_date
    errors.add_to_base('Data de encerramento deve ser após data de início') unless end_date > start_date
  end
  def max_greater_than_min_letters
    errors.add_to_base('Máximo de cartas não pode ser menor que mínimo') unless max_letters >= min_letters
  end

end
