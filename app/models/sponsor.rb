# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class Sponsor < ActiveRecord::Base

  validates :name, :presence => true, :uniqueness => true

  has_many :scholarships, :dependent => :restrict_with_exception

  has_paper_trail

  def to_label
    "#{self.name}"
  end
end
