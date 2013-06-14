# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Be sure to restart your server when you modify this file.

if Rails.env.production?
  Sapos::Application.config.session_store :cookie_store, :key => '_sapos_session'
else
  Sapos::Application.config.session_store :cookie_store, :key => '_sapos_session_h'
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Sapos::Application.config.session_store :active_record_store
