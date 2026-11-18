# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Botoes que acrescentam linhas a um subform do active_scaffold -- membros da
# comissao (professores, coordenacao, secretaria, credenciados) e campos do
# formulario (populate_field). Os .js.erb renderizam form_association_record
# com object:, e o partial do active_scaffold le a local record: NameError, e
# o botao responde 500.
RSpec.describe "Botoes de popular subform", type: :request do
  def xhr_get(path)
    get path, xhr: true, headers: { "Accept" => "text/javascript" }
  end

  def novas_linhas
    response.body.scan("ActiveScaffold.create_associated_record_form(").size
  end

  describe "membros da comissao" do
    before(:each) do
      sign_in create_confirmed_user(
        [FactoryBot.create(:role_coordenacao)], "coord.popular@ic.uff.br", "Coordenador Popular"
      )
      create_confirmed_user(
        [FactoryBot.create(:role_professor)], "prof.popular@ic.uff.br", "Professor Popular",
        professor: FactoryBot.create(:professor)
      )
    end

    # Controle: a acao chega ao populate_members com os professores. A parte que
    # falha e so a renderizacao, trocada aqui por um stub.
    it "escolhe os professores para a comissao" do
      capturados = nil
      allow_any_instance_of(Admissions::AdmissionCommitteesController)
        .to receive(:populate_members) do |controller, users|
          capturados = users.to_a
          controller.head :ok
        end

      xhr_get populate_professors_admission_committees_path(generated_id: "123", format: :js)

      expect(capturados.map(&:email)).to eq(["prof.popular@ic.uff.br"])
    end

    it "acrescenta uma linha por professor na comissao nova", pending: "issue #733" do
      xhr_get populate_professors_admission_committees_path(generated_id: "123", format: :js)

      expect(response).to have_http_status(:ok)
      expect(novas_linhas).to eq(1)
      expect(response.body).to include(Professor.last.name)
    end

    it "acrescenta as linhas na comissao existente sem gravar membro", pending: "issue #733" do
      comissao = FactoryBot.create(:admission_committee)

      expect do
        xhr_get populate_professors_admission_committee_path(comissao, format: :js)
      end.not_to change { Admissions::AdmissionCommitteeMember.count }

      expect(response).to have_http_status(:ok)
      expect(novas_linhas).to eq(1)
    end
  end

  describe "campos do formulario" do
    before(:each) do
      sign_in create_confirmed_user([FactoryBot.create(:role_administrador)], "adm.popular@ic.uff.br", "Adm")
    end

    it "acrescenta os campos no formulario novo", pending: "issue #733" do
      xhr_get populate_field_form_templates_path(generated_id: "1", format: :js)

      expect(response).to have_http_status(:ok)
      expect(novas_linhas).to be > 0
    end
  end
end
