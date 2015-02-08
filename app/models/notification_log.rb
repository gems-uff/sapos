# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class NotificationLog < ActiveRecord::Base
  attr_accessible :body, :notification_id, :subject, :to

  belongs_to :notification
end
