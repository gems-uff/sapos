# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreditsController < ApplicationController
  def show
    file_to_open = [Rails.root, 'README.md'].join(File::Separator)
    readme_file = File.open(file_to_open, "rb")
    file_content = readme_file.read

    @credits = file_content
  end

  def update_authorized?(record=nil)
    can? :update, record
  end

  def create_authorized?(record=nil)
    can? :create, record
  end

  def show_authorized?(record=nil)
    can? :read, record
  end

  def delete_authorized?(record=nil)
    can? :delete, record
  end
end
