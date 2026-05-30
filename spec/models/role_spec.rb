# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Role, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:user_roles).dependent(:restrict_with_exception) }
  it { should have_many(:users).through(:user_roles) }
end
