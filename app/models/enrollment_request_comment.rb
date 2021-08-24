# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequestComment < ApplicationRecord

  belongs_to :enrollment_request
  belongs_to :user
  
  validates :message, :presence => true
  validates :enrollment_request, :presence => true
  validates :user, :presence => true

  has_paper_trail

end
