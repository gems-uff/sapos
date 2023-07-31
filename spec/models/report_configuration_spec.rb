# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe ReportConfiguration, type: :model do
  let(:query) do
    ReportConfiguration.new(
      text: "config",
      order: 1,
      x: 100,
      y: 200,
      scale: 1
    )
  end
  subject { query }
  context "Validations" do
    it { should be_valid }
    it { should validate_presence_of(:text) }
    it { should validate_presence_of(:order) }
    it { should validate_presence_of(:x) }
    it { should validate_presence_of(:y) }
    it { should validate_presence_of(:scale) }
  end
end
