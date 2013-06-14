# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ProfessorResearchArea < ActiveRecord::Base
  belongs_to :professor
  belongs_to :research_area
end
