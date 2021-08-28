# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EmailTemplate < ApplicationRecord

  has_paper_trail

  validates :body, :presence => true 
  validates :to, :presence => true 
  validates :subject, :presence => true 


end
