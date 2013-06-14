# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentStatus < ActiveRecord::Base
   validates :name, :presence => true, :uniqueness => true
end
