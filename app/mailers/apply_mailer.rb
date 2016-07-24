class ApplyMailer < ApplicationMailer

  def letter_request_mail (request)
    @request = request
    mail(to: @request.professor_email, subject: "#{I18n.t 'apply.letter_request_mail_subject', student: @request.student_application.student.name}")
  end

  def student_token_mail (student_token)
    @student_token = student_token
    mail(to: @student_token.email, subject: I18n.t('apply.student_token_mail_subject') )
  end

  def application_finished_mail (student_token)
    @student_token = student_token
    mail(to: @student_token.student.email, subject: "#{I18n.t 'apply.application_finished_mail_subject', application_process: @student_token.application_process.name}")
  end
end
