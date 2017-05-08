class LetterRequestsController < ApplicationController
  skip_authorization_check
  skip_before_filter :authenticate_user!
  before_action :set_letter_request, only: [:update]

  def fill
    @letter_request = LetterRequest.find_by_access_token(params[:access_token])
    if @letter_request.is_filled?
      render text: 'ERRO - Carta já preenchida' and return
    else
      @letter_fields = FormField.where(form_template_id: @letter_request.student_application.application_process.letter_template_id).where.not(field_type: ['text', 'file'])
      @letter_texts = FormField.where(form_template_id: @letter_request.student_application.application_process.letter_template_id, field_type: 'text' )
      @letter_files = FormField.where(form_template_id: @letter_request.student_application.application_process.letter_template_id, field_type: 'file' )

      @letter_fields.each do |field|
        @letter_request.letter_field_inputs.new(form_field_id: field.id)
      end

      @letter_texts.each do |text|
        @letter_request.letter_text_inputs.new(form_field_id: text.id)
      end

      @letter_files.each do |file|
        @letter_request.letter_file_uploads.new(form_field_id: file.id)
      end
    end
  end

  def update
    @letter_request = LetterRequest.find(params[:id])
    if @letter_request.access_token == params[:letter_request][:access_token]
      if @letter_request.update(letter_request_params)
        render text: 'Carta preenchida com sucesso'
      else
        render text: 'ERRO - Letter update' and return
      end
    else
      render text: 'ERRO - Token da requisição inválido'
    end
  end

  private

    def set_letter_request
      @letter_request = LetterRequest.find(params[:id])
    end

    def letter_request_params
      params.require(:letter_request).permit(:professor_email, :student_application_id, :is_filled,
                                             letter_field_inputs_attributes: [:form_field_id, :input, :_destroy],
                                             letter_text_inputs_attributes: [:id, :letter_request_id, :form_field_id, :input, :_destroy],
                                             letter_file_uploads_attributes:[:id, :letter_request_id, :form_field_id, :file, :_destroy],
      )
    end

end