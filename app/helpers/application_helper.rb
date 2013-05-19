module ApplicationHelper
  def display_none_if_logged_out
    'style="display:none;"'.html_safe unless user_signed_in?
  end

  def transparent_if_logged_out
    'style="background: transparent;border: 0;"'.html_safe unless user_signed_in?
  end
end
