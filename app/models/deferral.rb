class Deferral < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :deferral_type
end
