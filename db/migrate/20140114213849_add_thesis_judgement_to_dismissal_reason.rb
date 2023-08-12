# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddThesisJudgementToDismissalReason < ActiveRecord::Migration[5.1]
  def change
    add_column :dismissal_reasons, :thesis_judgement, :string
  end
end
