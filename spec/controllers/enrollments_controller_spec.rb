# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"
require Rails.root.join "spec/controllers/concerns/enrollment_users_helper_spec.rb"

describe EnrollmentsController do
  it_behaves_like "enrollment_user_helper"
end