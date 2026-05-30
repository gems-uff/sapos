# frozen_string_literal: true

require "spec_helper"

RSpec.describe UserRole, type: :model do
  let(:user) { FactoryBot.build(:user) }
  let(:role) { FactoryBot.build(:role) }
  let(:user_role) do
    UserRole.new(
      user: user,
      role: role
    )
  end
  subject { user_role }
  describe "Validations" do
    it { should be_valid }
    it { should belong_to(:user).required(true) }
    it { should belong_to(:role).required(true) }
  end
end
