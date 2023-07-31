# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"
require Rails.root.join "spec/controllers/concerns/enrollment_users_helper.rb"

RSpec.describe EnrollmentsController, type: :controller do
  it_behaves_like "enrollment_user_helper"
end
