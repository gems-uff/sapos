class ApplyController < ApplicationController
  skip_authorization_check
  skip_before_filter :authenticate_user!
  before_action :set_application_process, only: [:new, :student_getid, :student_find, :fill_form, :student_confirm, :create, :update]

  def index
    @application_process = ApplicationProcess.is_open
  end

  def student_getid

  end

  def student_find
    @student = Student.find_by_cpf(params[:student][:cpf])
    if @student
      @student_token = StudentToken.new(:cpf => params[:student][:cpf], :email => @student.email, :student_id => @student.id, :application_process_id => params[:application_process_id] )
    else
      @student_token = StudentToken.new(:cpf => params[:student][:cpf], :email => params[:student][:email], :application_process_id => params[:application_process_id])
    end
    if @student_token.save
      ApplyMailer.student_token_mail(@student_token).deliver_later
    else
      render text: 'PQP - Student_find - Token Save'
    end
  end

  def student_confirm
    if @student_token.student_id
      #render text: @student_token.student_id.inspect
      #@apply = StudentApplication.new(application_process_id: @application_process.id, student_id: @student_token.student_id)
      @student = Student.find(@student_token.student_id)
    else
      #render text: 'No ID'
      #@apply = StudentApplication.new(application_process_id: @application_process.id)
      #@apply.students.new(email: @student_token.email, cpf: @student_token.cpf)
      @student = Student.new(email: @student_token.email, cpf: @student_token.cpf)
    end
  end

  def create
    @student = Student.new(student_params)
    unless @student.save
      render text: 'PQP - Student Create'
    end
    @student_token.student_id = @student.id
    unless @student_token.save
      render text: 'PQP - Student Create Token'
    end
    redirect_fill_form(@student_token.token)
    # if @student.save
    #   #render text: @student.student_applications.inspect
    #   # @student.student_application.letter_requests.each do |lr|
    #   #   ApplyMailer.letter_request_mail(lr).deliver_later
    #   # end
    #   # render text: 'OK'
    # else
    #   render text: 'PQP'
    # end
  end

  def update
    unless @student.update(student_params)
      render text: 'PQP - Student Update'
    end
    redirect_fill_form(@student_token.token)
  end

  def fill_form
    @application_form = FormTemplate.find(@application_process.form_template_id)
    @application_letter = FormTemplate.find(@application_process.letter_template_id)
    @application_fields = FormField.where(form_template_id: @application_form.id).where.not(field_type: ['text', 'file'])
    @application_texts = FormField.where(form_template_id: @application_form.id, field_type: 'text')
    @application_files = FormField.where(form_template_id: @application_form.id, field_type: 'file')

    @apply = StudentApplication.new(application_process_id: @application_process.id, student_id: @student_token.student_id)

    @application_fields.each do |field|
      @apply.form_field_inputs.new(form_field_id: field.id)
    end
    @application_texts.each do |text|
      @apply.form_text_inputs.new(form_field_id: text.id)
    end
    @application_files.each do |file|
      @apply.form_file_uploads.new(form_field_id: file.id)
    end
    @application_process.min_letters.to_i.times do |x|
      @apply.letter_requests.new
    end
  end

  private

  def set_application_process
    if params[:application_process_id]
      @application_process = ApplicationProcess.find(params[:application_process_id])
    elsif params[:student]
      @student_token = StudentToken.find_by_token(params[:student][:token])
      @application_process = ApplicationProcess.find(@student_token.application_process_id)
    elsif params[:student_application]
      @student_token = StudentToken.find_by_token(params[:student_application][:token])
      @application_process = ApplicationProcess.find(@student_token.application_process_id)
    else
      @student_token = StudentToken.find_by_token(params[:token])
      @application_process = ApplicationProcess.find(@student_token.application_process_id)
    end
    unless @application_process.is_open?
      redirect_to :apply
    end
  end

  def redirect_fill_form (token)
    redirect_to fill_form_url(token)
  end

  def student_params
    params.require(:student).permit(:address, :birth_city_id, :birth_state_id, :birthdate, :city_id, :civil_status, :cpf, :email,
                                    :employer, :father_name, :identity_expedition_date, :identity_issuing_body, :identity_issuing_place,
                                    :identity_number, :job_position, :mother_name, :name, :neighborhood, :obs, :sex, :telephone1,
                                    :telephone2, :zip_code,

                                    student_applications_attributes:[:id, :student_id, :application_process_id, :_destroy],

                                    form_field_inputs_attributes:[:id, :form_field_id, :input, :_destroy],
                                    form_text_inputs_attributes:[:id, :form_field_id, :input, :_destroy],
                                    form_file_uploads_attributes:[:id, :student_application_id, :form_field_id, :file, :_destroy],
                                    letter_requests_attributes:[:id, :professor_email, :student_application_id, :access_token, :is_filled, :_destroy]
    )
  end
end
