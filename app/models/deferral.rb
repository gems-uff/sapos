class Deferral < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :deferral_type

  def to_label
    "#{deferral_type.name}"    
  end
end
