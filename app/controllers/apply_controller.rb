class ApplyController < ApplicationController
  skip_authorization_check
  skip_before_filter :authenticate_user!
  before_action :set_application_process, only: [:new, :student_getid, :student_find, :fill_form]

  def index
    @application_process = ApplicationProcess.is_open
  end

  def fill_form
    @application_form = FormTemplate.find(@application_process.form_template_id)
    @application_letter = FormTemplate.find(@application_process.letter_template_id)
    @application_fields = FormField.where(form_template_id: @application_form.id).where.not(field_type: ['text', 'file'])
    @application_texts = FormField.where(form_template_id: @application_form.id, field_type: 'text')
    @application_files = FormField.where(form_template_id: @application_form.id, field_type: 'file')
    @apply = StudentApplication.new

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
      redirect_to :apply
    end
  end

  private

  def set_application_process
    if params[:application_process_id]
      @application_process = ApplicationProcess.find(params[:application_process_id])
    else
      @application_process = ApplicationProcess.find(StudentToken.find_by_token(params[:token]).application_process_id)
    end
    unless @application_process.is_open?
      redirect_to :apply
    end
  end

end
