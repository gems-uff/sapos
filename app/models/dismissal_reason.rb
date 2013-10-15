# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DismissalReason < ActiveRecord::Base
   validates :name, :presence => true, :uniqueness => true

   attr_accessible :name, :show_advisor_name

   has_paper_trail

   def to_label
  	"#{self.name}"
  end
end
