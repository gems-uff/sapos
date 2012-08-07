class LogoutController < ApplicationController
  def logout
    sign_out_and_redirect(current_user) if current_user && session[:sign_in_token] != current_user.current_sign_in_token
  end
end
