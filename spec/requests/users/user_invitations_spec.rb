# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Users::UserInvitationsController", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create :role_administrador
  end

  describe "GET /users/invitation/new" do
    it "redirects to the root path when signed in, as the invitation form is disabled" do
      sign_in create_confirmed_user([@role_adm], "inviter@ic.uff.br")

      get new_user_invitation_path

      expect(response).to redirect_to(root_path)
    end

    it "does not reach the invitation form when there is no signed in user" do
      get new_user_invitation_path

      expect(response).to_not have_http_status(:ok)
    end
  end

  describe "POST /users/invitation" do
    it "redirects to the root path without inviting, as the endpoint is disabled" do
      sign_in create_confirmed_user([@role_adm], "inviter@ic.uff.br")

      expect do
        post user_invitation_path, params: {
          user: { email: "invited@ic.uff.br", name: "Invited" }
        }
      end.to_not change { User.count }

      expect(response).to redirect_to(root_path)
      expect(User.find_by(email: "invited@ic.uff.br")).to be_nil
    end

    it "does not invite when there is no signed in user" do
      expect do
        post user_invitation_path, params: {
          user: { email: "invited@ic.uff.br", name: "Invited" }
        }
      end.to_not change { User.count }
    end
  end
end
