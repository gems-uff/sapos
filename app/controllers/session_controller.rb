# encoding: utf-8

require 'digest/sha1'

class SessionController < ApplicationController
  skip_before_filter :authenticate

  def create
    username = params[:name]
    password = params[:password]
    remember_me = params[:remember_me]

    #In case of first login with a newly created database, create a user with this password
    User.create(:name => username, :password => password) if User.count == 0

    if User.authenticate(username,password)
      user = User.find_by_name(username)
      session[:user_id] = user.id
      set_cookies_if_remember_me(remember_me,user.id,user.name)
      redirect_to :controller => :enrollments, :action => :index
    else
      redirect_to login_url, :alert => "Usuário ou senha inválidos"
    end
  end

  def destroy
    session[:user_id] = nil
    cookies.delete :remember_me_id if cookies[:remember_me_id]
    cookies.delete :remember_me_code if cookies[:remember_me_code]
    redirect_to login_url
  end

  def new
  end

  #methods for cookies and remember me functionality
  def set_cookies_if_remember_me(remember_me_param,user_id,user_name)
    if remember_me_param
      user_name = Digest::SHA1.hexdigest( user_name )[4,18]
      cookies[:remember_me_id] = { :value => user_id, :expires => 30.days.from_now }
      cookies[:remember_me_code] = { :value => user_name, :expires => 30.days.from_now }
    end
  end

end
