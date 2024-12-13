# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProgramLevel', js: true do

  let!(:program_level) { FactoryBot.create :program_level }
  let(:role) { FactoryBot.create :role_administrador }
  let(:user) { create_confirmed_user(role) }
  context 'edit', js: true do
    before(:each) do
      login_as(user)
      visit program_levels_path
    end
    it 'on update with different levels, should duplicate the old version' do
      expect(find(".level-column").text).to eq(program_level.level.to_s)
      expect(find(".start_date-column").text).to eq(I18n.l(program_level.start_date, format: :long))
      visit edit_program_level_path(program_level)
      fill_in "record[level]", with: "2"
      click_on "Atualizar"
      page.refresh
      expect(ProgramLevel.count).to eq(2)
    end
  end
end
