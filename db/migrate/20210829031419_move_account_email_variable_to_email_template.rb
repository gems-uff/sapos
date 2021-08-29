class MoveAccountEmailVariableToEmailTemplate < ActiveRecord::Migration[6.0]
  def up
    account_email = CustomVariable.where(variable: "account_email").first
    if account_email.present?
      EmailTemplate.create(
        name: "devise:invitation_instructions",
        body: account_email.value,
        subject:  "<%= t 'devise.mailer.invitation_instructions.subject' %>",
        to: "<%= @resource.email %>"
      )
      account_email.destroy
    end
  end

  def down
    template = EmailTemplate.where(name: "devise:invitation_instructions").first
    if template.present?
      CustomVariable.create(
        :description=>"Email de convite",
        :variable =>"account_email",
        :value => template.body
      )
      template.destroy
    end
  end
end
