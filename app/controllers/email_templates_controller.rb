class EmailTemplatesController < ApplicationController
  authorize_resource

  helper :notifications

  active_scaffold :"email_template" do |config|
    config.list.sorting = {:name => 'ASC'}

    columns = [:name, :to, :subject, :body, :enabled]
    config.create.columns = columns
    config.update.columns = columns
    config.list.columns = [:name, :enabled]

    config.create.label = :create_email_template_label
    config.update.label = :update_email_template_label

    config.actions.exclude :deleted_records    
  end

  def builtin
    result = EmailTemplate.load_template(params[:name])
    respond_to do |format|
      format.json { 
        render json: result
      }
    end
  end

end
