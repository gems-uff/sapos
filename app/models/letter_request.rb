class LetterRequest < ActiveRecord::Base
  before_save :set_access_token

  has_many :letter_field_inputs, :dependent => :delete_all
  has_many :letter_text_inputs, :dependent => :delete_all
  has_many :letter_file_uploads, :dependent => :delete_all
  belongs_to :student_application

  validates :professor_email, presence: true

  accepts_nested_attributes_for :letter_field_inputs,
                                allow_destroy: true
  accepts_nested_attributes_for :letter_text_inputs,
                                allow_destroy: true
  accepts_nested_attributes_for :letter_file_uploads,
                                allow_destroy: true

  def generate_access_token
    token = SecureRandom.urlsafe_base64
    while LetterRequest.exists?(access_token: token)
      token = SecureRandom.urlsafe_base64
    end
    return token
  end

  def set_access_token
    unless self.access_token?
      self.access_token = generate_access_token
    end
  end

end
