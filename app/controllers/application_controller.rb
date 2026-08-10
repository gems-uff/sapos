# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Sessão expirada com o formulário aberto derruba o token de CSRF. Sem
  # tratamento, o usuário recebe a página estática de 422, que fala em falta de
  # permissão em vez de sessão vencida, e a exceção ainda vira e-mail de erro.
  rescue_from ActionController::InvalidAuthenticityToken, with: :expired_session

  check_authorization unless: :devise_controller?

  skip_authorization_check only: [:root, :route_not_found]

  before_action :authenticate_user!
  before_action :parse_date
  before_action :set_paper_trail_whodunnit
  before_action :set_landing
  before_action :prepare_exception_notifier
  before_action :prepare_background

  clear_helpers

  # Defines which controller and action should be shown when the base
  # URL is acessed (root route in routes.rb).
  def root
    if can? :read, :landing
      return if redirect_to(controller: "landing", action: "index")
    end
    [
      Enrollment, Professor, ScholarshipDuration,
      Phase, Course, City, User, Student
    ].each do |model|
      if can? :read, model
        return if redirect_to(
          controller: model.name.underscore.pluralize.downcase, action: "index"
        )
      end
    end
  end

  private
    # Token de CSRF inválido tem duas causas bem diferentes, e cada uma pede um
    # destino e um aviso próprios.
    #
    # Sessão vazia é expiração — a página ficou horas aberta, o cookie caiu.
    # Não é defeito, ninguém é notificado, e o login é para onde o usuário
    # precisa ir de qualquer forma.
    #
    # Sessão com conteúdo e token que não bate é anomalia: defeito nosso,
    # formulário adulterado ou ataque. Sai e-mail, e o usuário volta para a
    # página de onde veio. Mandá-lo ao login estaria errado duas vezes: a sessão
    # dele não expirou, e o require_no_authentication do Devise devolveria quem
    # já está logado à raiz, trocando este aviso pelo "você já está logado".
    def expired_session(exception)
      if live_session?
        notify_invalid_token(exception)
        return head :unprocessable_entity unless request.format.html?

        return redirect_back fallback_location: root_path,
          alert: I18n.t("errors.invalid_form_token")
      end

      # Requisição sem navegação (js, json) não tem para onde redirecionar:
      # devolve o status e deixa o cliente decidir.
      return head :unprocessable_entity unless request.format.html?

      redirect_to new_user_session_path,
        alert: I18n.t("errors.session_expired")
    end

    def live_session?
      session.to_hash.except("session_id").present?
    end

    def notify_invalid_token(exception)
      ExceptionNotifier.notify_exception(exception,
        env: request.env,
        data: {
          user_id: current_user&.id,
          url: request.original_url,
          session_keys: session.to_hash.keys,
        }
      )
    end

    def prepare_background
      @simple_view = params[:simple_view].present?
      @show_background = user_signed_in?
    end

    def prepare_exception_notifier
      request.env["exception_notifier.exception_data"] = {
        user_id: current_user&.id,
        user_name: current_user&.name,
        user_email: current_user&.email,
        url: request.original_url,
      }
    end

    def set_landing
      @landingsidebar = Proc.new do |land|
        student_landing_menu(land)
      end
    end

    def student_landing_menu(land)
      return if current_user.blank? || current_user.student.blank?

      @emptylanding = true
      enrollments = current_user.student.enrollments.order(admission_date: :desc)
      enrollments.each do |enrollment|
        if enrollment.enrollment_status.user
          number = enrollment.enrollment_number
          path = student_enrollment_path(enrollment.id)
          land.item number, number, path,
            if: Proc.new { can?(:show, :student_enrollment) }
          @emptylanding = false
        end
      end

      if @emptylanding
        land.item :landing, "Principal", landing_url,
          if: Proc.new { can?(:read, :landing) }
      end
    end

    # def authenticate
    #   redirect_to login_url unless User.find_by_id(session[:user_id])
    # end

    # This application has custom values for date inputs,
    # having month and year as default for most dates
    # here we nullify invalid dates that comes from the request
    # invalid dates consists in dates with year < 1000
    def parse_date
      if params[:record]
        external_key = ""
        invalid_year = false
        params[:record].dup.each { |key, value|
          if key.include?("1i")
            invalid_year = value.to_i < 1000
            external_key = key.split("(")[0]
          end

          if invalid_year
            invalid_year = false
            params[:record].delete_if { |key, value|
              key.include?(external_key)
            }

            params[:record][external_key] = params[:record].delete(external_key)
          end
        }
      end
    end
end
