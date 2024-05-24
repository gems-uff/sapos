# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  # gives access to all helpers defined within `application_helper`.
  helper :application
  # Optional. eg. `confirmation_url`
  include Devise::Controllers::UrlHelpers
  # to make sure that your mailer uses the devise views
  default template_path: "devise/mailer"

  def headers_for(action, opts)
    headers = super
    headers[:subject] = render_to_string(
      inline: @template.subject
    ) unless @template.subject.nil?
    headers[:to] = render_to_string(
      inline: @template.to
    ) unless @template.to.nil?
    headers[:body] = render_to_string(
      inline: @template.body
    ) unless @template.body.nil?
    headers[:reply_to] = render_to_string(
      inline: CustomVariable.reply_to
    )
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
