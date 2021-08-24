# encoding utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EnrollmentRequestCommentsController < ApplicationController
  authorize_resource

  active_scaffold :"enrollment_request_comment" do |config|
    config.columns = [:enrollment_request, :user, :message, :updated_at]

    config.columns[:enrollment_request].form_ui = :record_select
    config.columns[:user].form_ui = :record_select

    config.actions.exclude :deleted_records

  end
end
