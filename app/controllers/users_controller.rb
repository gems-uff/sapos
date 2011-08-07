class UsersController < ApplicationController
  active_scaffold :user do |config|
    config.list.columns = [:name]
    config.create.columns = [:name, :password, :password_confirmation]
    config.update.columns = [:name, :password, :password_confirmation]
  end
end 