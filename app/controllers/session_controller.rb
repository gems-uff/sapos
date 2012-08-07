class SessionController < ApplicationController
  skip_before_filter :authenticate

  def create
    username = params[:name]
    password = params[:password]

    #In case of first login with a newly created database, create a user with this password
    User.create(:name => username, :password => password) if User.count == 0

    if User.authenticate(username,password)
      user = User.find_by_name(username)
      session[:user_id] = user.id
      redirect_to :controller => :enrollments, :action => :index
    else
      redirect_to login_url, :alert => "Usuário ou senha inválidos"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_url
  end

  def new
  end

end
