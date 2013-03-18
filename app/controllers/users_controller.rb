class UsersController < ApplicationController
  active_scaffold :user do |config|    
    config.list.columns = [:email, :name]
    config.columns = [:email, :name,:password,:password_confirmation]
    #config.create.columns = [:name, :password, :password_confirmation]
    #config.update.columns = [:name, :password, :password_confirmation]
    config.show.link = nil
    config.update.label = :update_user_label
    config.create.label = :create_user_label
    config.columns[:password].form_ui = :password
    config.columns[:password_confirmation].form_ui = :password
  end
end