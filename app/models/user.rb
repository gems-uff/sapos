require 'digest/sha2'

class User < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
  validates :password, :confirmation => true

  attr_accessor :password_confirmation
  attr_reader   :password

  validate :password_must_be_present

  def User.authenticate(name, password)
    if user = find_by_name(name)
      if user.hashed_password == encrypt_password(password, user.salt)
        user
      end
    end
  end

  def User.encrypt_password(password, salt)
    Digest::SHA2.hexdigest(password + "wibble" + salt)
  end

  # 'password' is a virtual attribute
  def password=(password)
    @password = password

    if password.present?
      generate_salt
      self.hashed_password = self.class.encrypt_password(password, salt)
    end
  end

  #Application need a user to log in
  def before_destroy
    errors.add(:base, I18n.t("activerecord.errors.models.user.self_delete")) if current_user_id == self.id
    errors.add(:base, I18n.t("activerecord.errors.models.user.delete")) if User.count == 1
    errors.blank?
  end

  def current_user_id
    @@user_id
  end

  def self.set_current_user_id(user_id)
    @@user_id = user_id
  end

  private

    def password_must_be_present
      errors.add(:password, "Missing password") unless hashed_password.present?
    end

    def generate_salt
      self.salt = self.object_id.to_s + rand.to_s
    end
end
