# encoding: utf-8
# Copyright (c) 2013 Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class CreditsController < ApplicationController
  skip_authorization_check
  require 'file_utils'

  def show
    links_content = FileUtils.file_content('LINKS')
    authors_content = FileUtils.file_content('AUTHORS')
    license_content = FileUtils.file_content('LICENSE')
    @header = "SAPOS main goal is to ease the management of information related to graduate programs such as enrollments, courses, advisement, scholarships, requirements, among others."
    @links = links_content
    @authors = authors_content
    @license = license_content
  end

end
