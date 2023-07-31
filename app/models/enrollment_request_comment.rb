# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a comment on a EnrollmentRequest made by an User
class EnrollmentRequestComment < ApplicationRecord
  has_paper_trail

  belongs_to :enrollment_request, optional: false
  belongs_to :user, optional: false

  validates :enrollment_request, presence: true
  validates :user, presence: true
  validates :message, presence: true
end
