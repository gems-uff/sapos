# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Sapos::Application.initialize!

APP_VERSION = `git describe --tag --always` unless defined? APP_VERSION
