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
    if @template.template_type == "ERB"
      headers[:subject] = render_to_string(
        inline: @template.subject
      ) unless @template.subject.nil?
      headers[:to] = render_to_string(
        inline: @template.to
      ) unless @template.to.nil?
      headers[:body] = render_to_string(
        inline: @template.body
      ) unless @template.body.nil?
      headers[:reply_to] = CustomVariable.reply_to
      @template.update_mailer_headers(headers)
    else
      name = @template.name.split(":", 2)[1]
      message = @template.prepare_message(
        self.send("liquid_#{name}")  
      )
      headers.update(message)
    end
    headers
  end

  def devise_mail(record, action, opts = {}, &block)
    @template = EmailTemplate.devise_template(action)
    if CustomVariable.redirect_email != "" && @template.enabled
      super
    end
  end

  def liquid_confirmation_instructions
    {
      user: @resource,
      confirmation_link: confirmation_url(@resource, confirmation_token: @token),
      user_email: @resource.unconfirmed_email || @resource.email
    }
  end

  def liquid_email_changed
    { 
      user: @resource,
      unconfirmed_email: @resource.try(:unconfirmed_email?)
    }
  end

  def liquid_invitation_instructions
    { 
      user: @resource,
      accept_invitation_link: accept_invitation_url(@resource, invitation_token: @token)
    }
  end

  def liquid_password_change
    { user: @resource }
  end

  def liquid_reset_password_instructions
    { 
      user: @resource,
      edit_password_link: edit_password_url(@resource, reset_password_token: @token)
    }
  end

  def liquid_unlock_instructions
    { 
      user: @resource,
      unlock_link: unlock_url(@resource, unlock_token: @token)
    }
  end

end
