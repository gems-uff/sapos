# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

require "spec_helper"

RSpec.describe DismissalReason, type: :model do
  it { should be_able_to_be_destroyed }
  let(:dismissal_reason) do
    DismissalReason.new(
      name: "Dismissal",
      thesis_judgement: DismissalReason::THESIS_JUDGEMENT.first
    )
  end
  subject { dismissal_reason }
  describe "Validations" do
    it { should be_valid }
    it { should validate_uniqueness_of(:name) }
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:thesis_judgement).in_array(DismissalReason::THESIS_JUDGEMENT) }
    it { should validate_presence_of(:thesis_judgement) }
  end
end
