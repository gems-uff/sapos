class StudentApplicationsController < ApplicationController
  # authorize_resource
  #
  # active_scaffold :student_application do |config|
  #   config.list.sorting = {:application_process => 'ASC'}
  #   config.list.columns = [:application_process, :student]
  #   #config.create.label = :create_city_label
  #   #config.columns[:state].form_ui = :select
  #   #config.columns[:state].clear_link
  #   #config.create.columns = [:state, :name]
  #   #config.update.label = :update_city_label
  #   #config.update.columns = [:state, :name]
  #
  #   config.actions.exclude :deleted_records
  # end
  skip_authorization_check
  skip_before_filter :authenticate_user!
  before_action :check_token, only: [:create]

  def create
    @student_application = StudentApplication.new(student_application_params)

    if @student_application.save
      @student_application.letter_requests.each do |lr|
        ApplyMailer.letter_request_mail(lr).deliver_later
      end
      @student_token.is_used = true
      @student_token.save
      render text: 'Finished' and return
    else
      render text: 'ERRO - StudentApplication' and return
    end
  end

  private

  def check_token
    @student_token = StudentToken.find_by_token(params[:student_application][:token])
    unless (@student_token.is_valid? and @student_token.application_process.is_open?)
      render text: 'ERRO - Student Application - Token inválido' and return
    end
    if StudentApplication.where(student_id: @student_token.student_id, application_process_id: @student_token.application_process_id).exists?
      render text: 'ERRO - Student Application - Candidato já inscrito' and return
    end
  end

  def student_application_params
    params.require(:student_application).permit(:student_id, :application_process_id,
                                                form_field_inputs_attributes:[:id, :form_field_id, :input, :_destroy],
                                                form_text_inputs_attributes:[:id, :form_field_id, :input, :_destroy],
                                                form_file_uploads_attributes:[:id, :student_application_id, :form_field_id, :file, :_destroy],
                                                letter_requests_attributes:[:id, :professor_email, :student_application_id, :access_token, :is_filled, :_destroy]
    )
  end

end