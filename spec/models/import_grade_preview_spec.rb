# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImportGradePreview, type: :model do
  it "apaga so as previas vencidas" do
    user = create_confirmed_user([FactoryBot.create(:role_administrador)], "admin@ic.uff.br")
    turma = FactoryBot.create(:course_class)
    velha = described_class.create!(user: user, course_class: turma, token: "a" * 32, data: "{}", created_at: 2.days.ago)
    nova = described_class.create!(user: user, course_class: turma, token: "b" * 32, data: "{}")

    described_class.purge_expired

    expect(described_class.exists?(velha.id)).to eq(false)
    expect(described_class.exists?(nova.id)).to eq(true)
  end
end
