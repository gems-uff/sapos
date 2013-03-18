class User < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true

  attr_accessible :email, :password, :password_confirmation, :remember_me

  devise :database_authenticatable, :recoverable, :rememberable, :registerable, :trackable, :confirmable,
         :lockable

  def valid_password?(password)
    if self.hashed_password.present?
      if encrypt_password(password, self.salt) == self.hashed_password
        self.password = password
        self.hashed_password = nil
        self.save!
        true
      else
        false
      end
    else
      super
    end
  end

  def reset_password!(*args)
    self.hashed_password = nil
    super
  end

  #Application need a user to log in
  def before_destroy
    errors.add(:base, I18n.t("activerecord.errors.models.user.self_delete")) if current_user_id == self.id
    errors.add(:base, I18n.t("activerecord.errors.models.user.delete")) if User.count == 1
    errors.blank?
  end
end
