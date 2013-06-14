# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Sapos::Application.initialize!

APP_VERSION = `git describe --tag --always` unless defined? APP_VERSION
