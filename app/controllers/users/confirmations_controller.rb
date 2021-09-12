# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  # GET /resource/confirmation/new
  # def new
  #   super
  # end

  # POST /resource/confirmation
  # def create
  #   super
  # end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    user = User.find_by(confirmation_token: params[:confirmation_token])
    email_before = user.email
    super do |user|
      if email_before != user.email && user.errors.empty?
        if student = user.student
          student.email = user.email
          student.save!
        end
        if professor = user.professor
          professor.email = user.email
          professor.save!
        end
      end
    end
  end

  # protected

  # The path used after resending confirmation instructions.
  # def after_resending_confirmation_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  # The path used after confirmation.
  # def after_confirmation_path_for(resource_name, resource)
  #   super(resource_name, resource)
  # end
end
