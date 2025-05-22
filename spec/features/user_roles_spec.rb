# frozen_string_literal: true

require "spec_helper"

RSpec.describe "UserRoles features", type: :feature do
  let(:url_path) { "/users" }
  let(:plural_name) { "user_roles" }
  let(:model) { User_Role }

  before(:all) do
    @destroy_later = []
    @destroy_all = []
    @destroy_all << @role_adm = FactoryBot.create(:role_administrador)
    @destroy_all << @role_prof = FactoryBot.create(:role_professor)
    @destroy_all << @role_cord = FactoryBot.create(:role_coordenacao)
    @destroy_all << @professor = FactoryBot.create(:professor, name: "Carol", cpf: "3")
    @destroy_all << @user = create_confirmed_user([@role_adm, @role_prof, @role_cord], professor: @professor)
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

  describe "view list page" do
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
end
