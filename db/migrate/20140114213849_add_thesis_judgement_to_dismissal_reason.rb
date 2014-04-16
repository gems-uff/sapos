# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class AddThesisJudgementToDismissalReason < ActiveRecord::Migration
  def change
    add_column :dismissal_reasons, :thesis_judgement, :string
  end
end
