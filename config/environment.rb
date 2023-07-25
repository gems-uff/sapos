# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!

APP_VERSION = `git describe --tag --always` unless defined? APP_VERSION
