# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::AdmissionsController < Admissions::ProcessBaseController
  before_action except: [:index, :find, :download] do
    find_admission_process(:id)
  end

  def index
    @admission_processes = Admissions::AdmissionProcess.open.where(visible: true)
    valores = recover_form_values
    @has_search_results = valores.present?
    @admission_application = Admissions::AdmissionApplication.new(valores)
  end

  def show
    if !@admission_process.require_session
      return redirect_to new_admission_apply_path(
        admission_id: @admission_process.simple_id
      )
    end
    application_params = recover_form_values
    @has_search_results = application_params.present?
    @admission_application = Admissions::AdmissionApplication.new(
      admission_process: @admission_process
    )
    if @has_search_results
      @admission_application.assign_attributes(application_params)
    end
  end

  def create
    @admission_application = Admissions::AdmissionApplication.find_by(
      admission_process: @admission_process,
      email: admission_application_params[:email]
    )

    if !@admission_process.allow_multiple_applications && @admission_application.present?
      if @admission_application.filled_form.is_filled
        @admission_application = Admissions::AdmissionApplication.new(
          admission_application_params.merge(
            admission_process: @admission_process
          )
        )
        flash.now[:alert] = I18n.t("errors.admissions.application_exists")
        return render :show
      else
        @admission_application.assign_attributes(admission_application_params)
      end
    else
      @admission_application = Admissions::AdmissionApplication.new(
        admission_application_params.merge(
          admission_process: @admission_process,
          filled_form: Admissions::FilledForm.new(
            is_filled: false,
            form_template: @admission_process.form_template
          )
        )
      )
    end
    if Rails.application.config.should_use_recaptcha && !verify_recaptcha(
      model: @admission_application,
      message: I18n.t("errors.admissions.invalid_captcha")
    )
      return render :show
    end

    if @admission_application.save
      if @admission_process.require_session
        add_token_to_session(@admission_application.token)
      end
      redirect_to edit_admission_apply_path(
        admission_id: @admission_process.simple_id,
        id: @admission_application.token
      )
    else
      render :show
    end
  end

  def find
    source = admission_application_params[:_source]
    if Rails.application.config.should_use_recaptcha && !verify_recaptcha()
      raise FindException.new I18n.t("errors.admissions.invalid_captcha")
    end

    if admission_application_params[:token] == "forgot"
      return find_by_email
    end

    @admission_application = Admissions::AdmissionApplication.find_by(
      token: admission_application_params[:token],
      email: admission_application_params[:email]
    )

    if !@admission_application.present?
      raise FindException.new I18n.t("errors.admissions.application_not_found")
    end

    if source.present? && source != @admission_application.admission_process.simple_id
      raise FindException.new I18n.t("errors.admissions.application_process_not_found")
    elsif @admission_application.filled_form.is_filled
      if @admission_application.admission_process.require_session
        add_token_to_session(@admission_application.token)
      end
      redirect_to admission_apply_path(
        admission_id: @admission_application.admission_process.simple_id,
        id: @admission_application.token
      )
    else
      if @admission_application.admission_process.require_session
        add_token_to_session(@admission_application.token)
      end
      redirect_to edit_admission_apply_path(
        admission_id: @admission_application.admission_process.simple_id,
        id: @admission_application.token
      )
    end
  rescue FindException => e
    # O codigo de identificacao e a CREDENCIAL da inscricao: com ele a tela
    # /admissions/<processo>/apply/<token> abre, e em processo sem
    # require_session ele basta, de qualquer navegador. Repeti-lo na query
    # string do redirect o leva para o log de acesso do servidor, para o
    # historico do navegador e para qualquer link que o candidato compartilhe
    # ao pedir ajuda -- e isso acontece tambem quando o token esta CORRETO e
    # quem falhou foi o captcha, que expira sozinho.
    #
    # O find_by_email abaixo ja separava os dois: a URL que ele monta, e que vai
    # por mensagem, leva so o e-mail. Aqui os valores viajam pelo flash, que
    # mora na sessao, e a URL nao carrega nenhum deles.
    flash[:recover] = admission_application_params.slice(:email, :token).to_h
    if source.blank?
      redirect_to admissions_path, alert: e.message
    else
      redirect_to admission_path(id: source), alert: e.message
    end
  end

  protected
    def find_by_email
      @admission_applications = Admissions::AdmissionApplication.where(
        email: admission_application_params[:email]
      )
      source = admission_application_params[:_source]

      if @admission_applications.blank?
        raise FindException.new I18n.t("errors.admissions.application_not_found")
      end

      if source.present?
        @admission_applications = @admission_applications
        .joins(:admission_process)
        .where('
          `admission_processes`.`simple_url` = :process_id OR
          `admission_processes`.`id` = :process_id',
          process_id: source
        )

        if source.to_i.to_s == source
          @admission_applications = @admission_applications.filter do |x|
            x.admission_process.is_open? || x.admission_process.is_open_to_edit?
          end
        end

        if @admission_applications.blank?
          raise FindException.new I18n.t("errors.admissions.application_process_not_found")
        end
      end

      if source.blank?
        path = admissions_url(
          params: admission_application_params.extract!(:email)
        )
      else
        path = admission_url(
          id: source,
          params: admission_application_params.extract!(:email)
        )
      end

      emails = [EmailTemplate.load_template(
        "admissions/admissions:recover_tokens"
      ).prepare_message({
        email: admission_application_params[:email],
        admission_applications: @admission_applications,
        url: path
      })]
      Notifier.send_emails(notifications: emails)

      redirect_to path, notice: I18n.t(
        "admissions.admissions.find_by_email.success",
        email: admission_application_params[:email],
        count: @admission_applications.length
      )
    end

  private
    def set_show_background
      @show_background = true
    end

    def admission_application_params
      params.require(:admissions_admission_application).permit(
        :name, :email, :token, :_source
      )
    end

    def optional_admission_application_params
      params.permit(:email, :token)
    end

    # De onde o formulario de recuperacao se repreenche. A query string ainda
    # vale -- e o caminho do find_by_email, que manda o link por mensagem --,
    # mas a recusa do #find passa os valores pelo flash, para nao deixar a
    # credencial na URL.
    def recover_form_values
      parametros = optional_admission_application_params
      return parametros.to_h if parametros.present?

      (flash[:recover] || {}).slice("email", "token")
    end
end


class FindException < StandardError
  def initialize(msg, exception_type = "find_exception")
    @exception_type = exception_type
    super(msg)
  end
end
