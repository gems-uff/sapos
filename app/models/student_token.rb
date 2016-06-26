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
end
