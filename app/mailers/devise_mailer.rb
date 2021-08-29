# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class DeviseMailer < Devise::Mailer   
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def headers_for(action, opts)
    headers = super
    headers[:subject] = render_to_string(inline: @template.subject) unless @template.subject.nil?
    headers[:to] = render_to_string(inline: @template.to) unless @template.to.nil?
    headers[:body] = render_to_string(inline: @template.body) unless @template.body.nil?
    @template.update_mailer_headers(headers)
    headers
  end

  def devise_mail(record, action, opts = {}, &block)
    @template = EmailTemplate.devise_template(action)
    if CustomVariable.redirect_email != "" && @template.enabled
      super
    end
  end

end