# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file

class FormImage < ApplicationRecord
  has_paper_trail
  has_and_belongs_to_many  :form_templates

  mount_uploader :image, FormImageUploader

  def initialize_dup(other)
    super
    attrib = other.attributes.except("id", "created_at", "updated_at")
    self.assign_attributes(attrib)
  end

  def mount_uploader_name
    :image
  end

  def to_label
    "#{name}"
  end

end
