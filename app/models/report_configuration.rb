# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class ReportConfiguration < ActiveRecord::Base
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
