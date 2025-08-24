# frozen_string_literal: true

require "spec_helper"

RSpec.describe "UserRoles features", type: :feature do
  let(:url_path) { "/user_roles" }
  let(:plural_name) { "user_roles" }
  let(:model) { User_Role }

  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @role_prof = FactoryBot.create(:role_professor)
    @destroy_all << @role_cord = FactoryBot.create(:role_coordenacao)
    @destroy_all << @professor = FactoryBot.create(:professor, name: "ana", cpf: "3")
    @destroy_all << @user = create_confirmed_user([@role_adm, @role_prof, @role_cord], professor: @professor)

    @destroy_all << FactoryBot.create(:user, email: "user3@ic.uff.br", name: "carol", roles: [@role_cord])
    @destroy_all << @record = FactoryBot.create(:user, email: "user2@ic.uff.br", name: "bia", roles: [@role_adm, @role_cord])
  end

  after(:each) do
    @destroy_later.each(&:delete)
    @destroy_later.clear
  end

  after(:all) do
    @destroy_all.each(&:delete)
    @destroy_all.clear
    UserRole.delete_all
  end

  describe "view roles combo" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should go to the professor page, when selecionated" do
      select "Professor", from: "role_id"
      expect(page).to have_select("role_id", selected: "Professor")
    end

    it "should go to the coordination page, when selecionated" do
      select "Coordenação", from: "role_id"
      expect(page).to have_select("role_id", selected: "Coordenação")
    end
  end

  describe "view user roles list" do
    before(:each) do
      login_as(@user)
      visit url_path
    end

    it "should show table" do
      expect(page).to have_content "Papéis de Usuários"
      expect(page.all("tr th").map(&:text)).to eq [
        "Usuário", "Papel", ""
      ]
    end

    it "should by default order by id" do
      expect(page.all("tr td.user-column").map(&:text)).to eq ["ana", "ana", "ana", "carol", "bia", "bia"]
    end

    it "should order by user name, asc, when clicked" do
      click_link_and_wait "Usuário"
      expect(page.all("tr td.user-column").map(&:text)).to eq ["ana", "ana", "ana", "bia", "bia", "carol"]
    end

    it "should order by user name, desc, when clicked twice" do
      click_link_and_wait "Usuário"
      click_link_and_wait "Usuário"
      expect(page.all("tr td.user-column").map(&:text)).to eq ["carol", "bia", "bia", "ana", "ana", "ana"]
    end

    it "should order by role name, asc, when clicked" do
      click_link_and_wait "Papel"
      expect(page.all("tr td.user-column").map(&:text)).to eq ["ana", "bia", "ana",  "carol", "bia", "ana"]
    end

    it "should order by role name, desc, when clicked twice" do
      click_link_and_wait "Papel"
      click_link_and_wait "Papel"
      expect(page.all("tr td.user-column").map(&:text)).to eq ["ana", "ana", "carol", "bia", "ana", "bia"]
    end
  end
end
