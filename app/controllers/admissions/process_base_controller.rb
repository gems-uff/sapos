# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::ProcessBaseController < ApplicationController
  skip_authorization_check
  skip_authorize_resource
  skip_before_action :authenticate_user!
  skip_before_action :prepare_background
  before_action :set_show_background

  protected
    def find_admission_process(param_id)
      @admission_process =
        Admissions::AdmissionProcess.open.find_by(simple_url: params[param_id]) ||
        Admissions::AdmissionProcess.open.find_by(id: params[param_id])
      if @admission_process.blank?
        redirect_to admissions_path,
          alert: I18n.t("errors.admissions.invalid_process")
      end
    end

    def add_token_to_session(token)
      session[:admission_tokens] = Set.new if session[:admission_tokens].blank?
      session[:admission_tokens].add(token)
    end

  private
    def set_show_background
      @show_background = true
    end
end
