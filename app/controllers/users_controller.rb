class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.list.columns = [:name]
    config.create.columns = [:name, :password, :password_confirmation]
    config.update.columns = [:name, :password, :password_confirmation]
    config.update.label = :update_user_label
    config.create.label = :create_user_label
  end
end 