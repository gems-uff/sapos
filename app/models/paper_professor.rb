# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class PaperProfessor < ApplicationRecord
  has_paper_trail

  belongs_to :paper, optional: false
  belongs_to :professor, optional: false

  def to_label
    "#{self.professor.to_label} - #{self.paper.to_label}"
  end
end
