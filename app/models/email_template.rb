# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

class EmailTemplate < ApplicationRecord

  has_paper_trail

  validates_uniqueness_of :name, :allow_blank => true
  validates :body, :presence => true 
  validates :to, :presence => true 
  validates :subject, :presence => true 

  BUILTIN_TEMPLATES = {
    "devise:confirmation_instructions" => {
      path: File.join("devise", "mailer", "confirmation_instructions.text.erb"),
      subject: "<%= t 'devise.mailer.confirmation_instructions.subject' %>",
      to: "<%= @resource.email %>",
    },
    "devise:email_changed" => {
      path: File.join("devise", "mailer", "email_changed.text.erb"),
      subject: "<%= t 'devise.mailer.email_changed.subject' %>",
      to: "<%= @resource.email %>",
    },
    "devise:invitation_instructions" => {
      path: File.join("devise", "mailer", "invitation_instructions.text.erb"),
      subject: "<%= t 'devise.mailer.invitation_instructions.subject' %>",
      to: "<%= @resource.email %>",
    },
    "devise:password_change" => {
      path: File.join("devise", "mailer", "password_change.text.erb"),
      subject: "<%= t 'devise.mailer.password_change.subject' %>",
      to: "<%= @resource.email %>",
    },
    "devise:reset_password_instructions" => {
      path: File.join("devise", "mailer", "reset_password_instructions.text.erb"),
      subject: "<%= t 'devise.mailer.reset_password_instructions.subject' %>",
      to: "<%= @resource.email %>",
    },
    "devise:unlock_instructions" => {
      path: File.join("devise", "mailer", "unlock_instructions.text.erb"),
      subject: "<%= t 'devise.mailer.unlock_instructions.subject' %>",
      to: "<%= @resource.email %>",
    },
    
  }

  def self.devise_template(action)
    name = "devise:#{action}"
    self.load_template(name)
  end

  def self.load_template(name)
    template = EmailTemplate.find_by_name(name)
    if template.nil?
      template = EmailTemplate.new
      builtin = BUILTIN_TEMPLATES[name] 
      unless builtin.nil?
        template.subject = builtin[:subject]
        template.to = builtin[:to]
        template.body = File.read File.join(Rails.root, "app", "views", builtin[:path])
      end
    end
    template
  end

  def update_mailer_headers(headers)
    unless CustomVariable.redirect_email.nil?
      headers[:subject] = headers[:subject] + " (Originalmente para #{headers[:to]})"
      headers[:to] = CustomVariable.redirect_email
    end
  end    

end
