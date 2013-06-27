# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreditsController < ApplicationController
  skip_authorization_check

  def show
    file_to_open = [Rails.root, 'README.md'].join(File::Separator)
    readme_file = File.open(file_to_open, "rb")
    file_content = readme_file.read

    @credits = file_content
  end

  def authors
    file_to_open = [Rails.root, 'AUTHORS'].join(File::Separator)
    readme_file = File.open(file_to_open, "rb")
    file_content = readme_file.read

    @authors = file_content
  end

  def license
    file_to_open = [Rails.root, 'LICENSE'].join(File::Separator)
    readme_file = File.open(file_to_open, "rb")
    file_content = readme_file.read

    @license = file_content
  end

end
