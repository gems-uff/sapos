# frozen_string_literal: true

class SkinColor < ApplicationRecord
  has_paper_trail
  
  has_many :students, foreign_key: "skin_color_id"
end
