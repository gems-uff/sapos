# frozen_string_literal: true

class Affiliation < ApplicationRecord
  has_paper_trail

  belongs_to :institution
  belongs_to :professor

end
