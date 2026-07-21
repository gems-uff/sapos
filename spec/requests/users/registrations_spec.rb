# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Users::RegistrationsController", type: :request do
  before(:each) do
    @role_adm = FactoryBot.create :role_administrador
  end

  describe "GET /users/sign_up" do
    it "redirects to the sign in page, as self registration is disabled" do
      expect { get new_user_registration_path }.to_not change { User.count }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /users/profile" do
    it "redirects to the sign in page when there is no signed in user" do
      get edit_user_registration_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "shows the profile of the signed in user" do
      sign_in create_confirmed_user([@role_adm], "profile@ic.uff.br")

      get edit_user_registration_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /users/profile" do
    it "updates the password of the signed in user" do
      user = create_confirmed_user([@role_adm], "profile@ic.uff.br")
      sign_in user

      patch user_registration_path, params: {
        user: {
          password: "N3w!p4ssw0rd",
          password_confirmation: "N3w!p4ssw0rd",
          current_password: "A1b2c3d4!",
        }
      }

      expect(user.reload.valid_password?("N3w!p4ssw0rd")).to be(true)
    end

    it "keeps the password when the current password is wrong" do
      user = create_confirmed_user([@role_adm], "profile@ic.uff.br")
      sign_in user

      patch user_registration_path, params: {
        user: {
          password: "N3w!p4ssw0rd",
          password_confirmation: "N3w!p4ssw0rd",
          current_password: "wrong password",
        }
      }

      expect(user.reload.valid_password?("A1b2c3d4!")).to be(true)
    end

    it "requires confirmation of a new email before replacing the current one" do
      user = create_confirmed_user([@role_adm], "profile@ic.uff.br")
      sign_in user

      patch user_registration_path, params: {
        user: {
          email: "changed@ic.uff.br",
          current_password: "A1b2c3d4!",
        }
      }

      user.reload
      expect(user.email).to eq("profile@ic.uff.br")
      expect(user.unconfirmed_email).to eq("changed@ic.uff.br")
    end
  end
end
