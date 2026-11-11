# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Nada impede o mesmo usuário em duas linhas de membro do mesmo comitê.
RSpec.describe "Membro repetido no comitê", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_coordenacao)], "duplicate_member_coord@ic.uff.br", "Coord")
    @professor = professor_user("duplicate-member-prof@ic.uff.br")
    @other = professor_user("duplicate-member-other@ic.uff.br")
  end

  def create_committee(name, users)
    members = users.each_with_index.to_h { |user, i| [(1000 + i).to_s, { "user" => user.id.to_s }] }
    post admission_committees_path, params: { record: { name: name, members: members } }
    Admissions::AdmissionCommittee.find_by(name: name)
  end

  it "grava um membro por usuário" do
    expect(create_committee("Comitê", [@professor, @other]).members.count).to eq(2)
  end

  it "não grava o mesmo usuário duas vezes", pending: "issue #773" do
    committee = create_committee("Comitê", [@professor, @professor])
    expect(committee.nil? || committee.members.where(user: @professor).count == 1).to be true
  end
end
