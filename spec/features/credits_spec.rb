# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Credits features", type: :feature do
  describe "show page" do
    before(:each) do
      visit "/credits/show"
    end

    it "should show readme" do
      expect(page).to have_content "Créditos"
      expect(page).to have_content "Team"
    end
  end
end
