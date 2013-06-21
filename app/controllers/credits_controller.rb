# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreditsController < ApplicationController
  def show
    links_content = FileUtils.file_content('LINKS')
    authors_content = FileUtils.file_content('AUTHORS')
    license_content = FileUtils.file_content('LICENSE')
    @header = "SAPOS main goal is to ease the management of information related to graduate programs such as enrollments, courses, advisement, scholarships, requirements, among others."
    @links = links_content
    @authors = authors_content
    @license = license_content
  end

  def update_authorized?(record=nil)
    can? :update, record
  end

  def create_authorized?(record=nil)
    can? :create, record
  end

  def show_authorized?(record=nil)
    can? :read, record
  end

  def delete_authorized?(record=nil)
    can? :delete, record
  end
end
