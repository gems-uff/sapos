module ApplicationHelper
  def set_style_display_none_if_logged_out
    "style='display:none;'" unless session[:user_id]
  end

  def set_style_menu_content_if_logged_out
    "style='background: transparent;border: 0;'" unless session[:user_id]
  end
end
