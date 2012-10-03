module ApplicationHelper
  def display_none_if_logged_out
    "style='display:none;'" unless session[:user_id]
  end

  def transparent_if_logged_out
    "style='background: transparent;border: 0;'" unless session[:user_id]
  end
end
