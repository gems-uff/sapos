# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Be sure to restart your server when you modify this file.

if Rails.env.production?
  Sapos::Application.config.session_store :cookie_store, key: '_sapos_session'
else
  Sapos::Application.config.session_store :cookie_store, key: '_sapos_session_h'
end
