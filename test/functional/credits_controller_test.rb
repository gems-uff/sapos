# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require 'test_helper'

class CreditsControllerTest < ActionController::TestCase
  test "should get show" do
    get :show
    assert_response :success
  end

end
