# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Lista embutida do active_scaffold recebe as condicoes pela URL
# (embedded[conditions]). So o marcador "pendency" das listas de pendencias
# tem efeito, e a condicao e montada no servidor
# (config/initializers/active_scaffold_embedded_conditions.rb).
RSpec.describe "Condicoes de lista embutida", type: :request do
  before(:each) do
    sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm_embutida@ic.uff.br", "Adm")
    FactoryBot.create(:student, name: "Aluna Alfa")
    FactoryBot.create(:student, name: "Aluno Beta")
  end

  def nomes(params)
    get students_path, params: params
    expect(response).to have_http_status(:ok)
    ["Aluna Alfa", "Aluno Beta"].select { |nome| response.body.include?(nome) }
  end

  it "lista todos sem condicao" do
    expect(nomes({})).to eq(["Aluna Alfa", "Aluno Beta"])
  end

  it "ignora condicao em texto vinda da URL" do
    expect(nomes(embedded: { conditions: "students.name = 'Aluna Alfa'" })).to eq(["Aluna Alfa", "Aluno Beta"])
  end

  it "ignora condicao em lista vinda da URL" do
    expect(nomes(embedded: { conditions: ["students.name = 'Aluna Alfa'"] })).to eq(["Aluna Alfa", "Aluno Beta"])
  end

  it "ignora o marcador de pendencia em lista que nao tem pendencia" do
    expect(nomes(embedded: { conditions: "pendency" })).to eq(["Aluna Alfa", "Aluno Beta"])
  end
end

# A pagina de pendencias embute a lista de pedidos de inscricao em disciplina filtrada aos
# pendentes; o navegador pede a lista pela URL do marcador, e o filtro tem de
# vir dessa URL de volta.
RSpec.describe "Lista de pendencias embutida", type: :request do
  before(:each) do
    # Secretaria le as pendencias de pedidos de inscricao em disciplina (Ability).
    sign_in create_confirmed_user([FactoryBot.create(:role_secretaria)], "sec_pend@ic.uff.br", "Sec")
    turma = FactoryBot.create(:course_class)
    pendente = FactoryBot.create(:enrollment_request,
      enrollment: FactoryBot.create(:enrollment, enrollment_number: "M-PENDENTE"))
    FactoryBot.create(:class_enrollment_request, enrollment_request: pendente, course_class: turma)
    resolvido = FactoryBot.create(:enrollment_request,
      enrollment: FactoryBot.create(:enrollment, enrollment_number: "M-RESOLVIDO"))
    FactoryBot.build(:class_enrollment_request, enrollment_request: resolvido, course_class: turma,
      status: ClassEnrollmentRequest::INVALID).save!(validate: false)
  end

  it "traz so o pedido pendente pela URL que a pagina de pendencias gera" do
    get pendencies_path
    marcador = Nokogiri::HTML(response.body).css(".active-scaffold-component[data-refresh]")
      .find { |div| div["data-refresh"].start_with?("/class_enrollment_requests?") }
    expect(marcador).to be_present

    get CGI.unescapeHTML(marcador["data-refresh"]), xhr: true

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("M-PENDENTE")
    expect(response.body).not_to include("M-RESOLVIDO")
  end
end
