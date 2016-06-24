class ApplyMailer < ApplicationMailer
  default from: 'sapos@brunodess.com'

  def letter_request_mail (request)
    @request = request
    mail(to: @request.professor_email, subject: "Recommendation Letter Requested for: #{@request.student_application.student_name}")
  end
end
