# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Represents a notification log
class NotificationLog < ApplicationRecord
  belongs_to :notification, optional: true
end
