# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

describe Role do
  it { should be_able_to_be_destroyed }
  it { should restrict_destroy_when_exists :user }
end