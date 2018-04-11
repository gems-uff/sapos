# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddPhotoToStudents < ActiveRecord::Migration[5.1]
  def change
    add_column :students, :photo, :string
  end
end
