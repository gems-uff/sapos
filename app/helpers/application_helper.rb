# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

module ApplicationHelper
  include NumbersHelper

  def display_none_if_logged_out
    'style="display:none;"'.html_safe unless user_signed_in?
  end

  def transparent_if_logged_out
    'style="background: transparent;border: 0;"'.html_safe unless user_signed_in?
  end
end
