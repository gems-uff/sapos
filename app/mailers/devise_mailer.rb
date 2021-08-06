# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DeviseMailer < Devise::Mailer   
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def invitation_instructions(record, token, opts={})
    @token = token
    @footer = CustomVariable.notification_footer
    devise_mail(record, :invitation_instructions, opts) do |format|
      template = CustomVariable.account_email
      if template.nil?
        format.text
      else
        format.text { render inline: template }
      end
    end
  end
end