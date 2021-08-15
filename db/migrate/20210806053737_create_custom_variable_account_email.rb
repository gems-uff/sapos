class CreateCustomVariableAccountEmail < ActiveRecord::Migration[6.0]
  def up
    CustomVariable.where(:variable => "account_email").first or CustomVariable.create(:description=>"Email de convite", :variable =>"account_email", :value => "<%= @resource.name %>,

Informamos que a sua conta no SAPOS foi criada.

Acesse o seguinte link para confirmar e definir sua senha:
<%= accept_invitation_url(@resource, invitation_token: @token) %>



<%= CustomVariable.notification_footer %>")
  end

  def down
  end
end

