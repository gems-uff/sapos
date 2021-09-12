# encoding: utf-8
# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.


class Users::UserInvitationsController < Devise::InvitationsController
  def new
    redirect_to root_path
  end
  def create
    redirect_to root_path
  end
end