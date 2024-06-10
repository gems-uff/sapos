# frozen_string_literal: true

RSpec.describe SkinColor, type: :model do
  it{ should be_able_to_be_destroyed }
  it{ should have_many(:students) }
end
