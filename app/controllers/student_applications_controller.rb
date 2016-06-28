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

  def create
    @student_application = StudentApplication.new(student_application_params)

    if @student_application.save
      @student_application.letter_requests.each do |lr|
        ApplyMailer.letter_request_mail(lr).deliver_later
      end
      render text: 'Finished'
    else
      render text: 'NOK - StudentApplication'
    end
  end

  private

  def student_application_params
    params.require(:student_application).permit(:student_id, :application_process_id,
                                                form_field_inputs_attributes:[:id, :form_field_id, :input, :_destroy],
                                                form_text_inputs_attributes:[:id, :form_field_id, :input, :_destroy],
                                                form_file_uploads_attributes:[:id, :student_application_id, :form_field_id, :file, :_destroy],
                                                letter_requests_attributes:[:id, :professor_email, :student_application_id, :access_token, :is_filled, :_destroy]
    )
  end

end