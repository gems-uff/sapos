class StudentToken < ActiveRecord::Base
  before_save :set_token
  
  belongs_to :student
  belongs_to :application_process

  #validates :token, presence: true, uniqueness: true

  def generate_token
    token = SecureRandom.urlsafe_base64
    while StudentToken.exists?(token: token)
      token = SecureRandom.urlsafe_base64
    end
    return token
  end

  def set_token
    unless self.token?
      self.token = generate_token
    end
  end

  def is_valid?
    if (DateTime.now.to_f - self.created_at.to_f) > (24*3600) or self.is_used?
      false
    else
      true
    end
  end

  def unique_cpf_application_id
    if StudentToken.where(application_process_id: application_process_id, cpf: cpf).first.created_at < created_at
      errors.add_to_base('Já existe')
    end
  end

end
