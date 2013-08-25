# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreditsController < ApplicationController
  skip_authorization_check
  require 'file_utils'

  def show
    @readme = FileUtils.file_content('README.md', 'rt')
  end

end
