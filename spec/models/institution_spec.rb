# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Institution, type: :model do
  it { should be_able_to_be_destroyed }
  it { should have_many(:majors).dependent(:restrict_with_exception) }
  it { should have_many(:affiliations).dependent(:restrict_with_exception) }
  it { should have_many(:professors).through(:affiliations) }

  let(:institution) { Institution.new(name: "instituicao") }
  subject { institution }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
  end
end
