# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreditsController < ApplicationController
  skip_authorization_check
  skip_before_action :authenticate_user!

  def show
    @show_background = true
    @readme = File.read(Rails.root.join("README.md"))
  end
end
