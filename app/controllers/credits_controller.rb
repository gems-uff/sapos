# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreditsController < ApplicationController
  skip_authorization_check
  skip_before_action :authenticate_user!

  require 'file_utils'

  def show
    @readme = FileUtils.file_content('README.md', 'rt')
  end

end
