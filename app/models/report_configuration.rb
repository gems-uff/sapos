# Copyright (c) 2014 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ReportConfiguration < ActiveRecord::Base
  attr_accessible :image, :name, :show_sapos, :text, :use_at_grades_report, 
  				  :use_at_report, :use_at_schedule, :use_at_transcript, :order,
  				  :x, :y, :scale
  has_paper_trail

  validates :text, :presence => true
  validates :order, :presence => true
  validates :x, :presence => true
  validates :y, :presence => true
  validates :scale, :presence => true

  mount_uploader :image, ImageUploader
  skip_callback :commit, :after, :remove_image!

  def initialize_dup(other)
    super
    attrib = other.attributes.except("id", "created_at", "updated_at")
    self.assign_attributes(attrib)
  end


end
