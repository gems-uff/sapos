# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O formulário de Professor tem subform de filiações, então a filiação que
# termina e a que começa chegam no mesmo envio. A validação de sobreposição
# compara cada linha com as outras do subform em memória, e só consulta o
# banco para as demais. Estes exemplos passam pela tela para medir esse
# caminho, e não o do modelo.
RSpec.describe "Filiações pelo subform de Professor", type: :request do
  before(:each) do
    @role_administrador = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_administrador], "adm_filiacao@ic.uff.br", "Administrador")
    @professor = FactoryBot.create(:professor)
    @uff = FactoryBot.create(:institution)
    @outra = FactoryBot.create(:institution)
    sign_in @admin
  end

  def filiacao(instituicao, inicio, fim, id: nil)
    attrs = {
      institution: instituicao.id.to_s,
      start_date: I18n.l(inicio),
      end_date: fim ? I18n.l(fim) : ""
    }
    attrs[:id] = id.to_s if id
    attrs
  end

  def atualizar_professor(filiacoes)
    put professor_path(@professor), params: {
      record: {
        name: @professor.name,
        affiliations: filiacoes.each_with_index.to_h { |f, i| [f[:id] || "#{1000 + i}", f] }
      }
    }
  end

  describe "troca de instituição" do
    before(:each) do
      @aberta = FactoryBot.create(
        :affiliation, professor: @professor, institution: @uff,
        start_date: Time.zone.local(2015, 1, 1), end_date: nil
      )
    end

    # A validação anterior lia o banco, onde a filiação ainda estava aberta, e
    # recusava a nova: a secretaria precisava de dois envios.
    it "encerra a filiação aberta e abre a nova no mesmo envio" do
      atualizar_professor([
        filiacao(@uff, Date.new(2015, 1, 1), Date.new(2024, 3, 1), id: @aberta.id),
        filiacao(@outra, Date.new(2024, 3, 1), nil)
      ])

      expect(@aberta.reload.end_date.to_date).to eq(Date.new(2024, 3, 1))
      expect(@professor.affiliations.reload.map(&:institution)).to contain_exactly(@uff, @outra)
    end

    # Controle do exemplo acima: sem encerrar a aberta, a nova a cruza e o
    # envio é recusado. Sem ele, o sucesso acima poderia ser só a validação
    # que deixou de existir.
    it "recusa abrir a nova sem encerrar a aberta" do
      atualizar_professor([
        filiacao(@uff, Date.new(2015, 1, 1), nil, id: @aberta.id),
        filiacao(@outra, Date.new(2024, 3, 1), nil)
      ])

      expect(@aberta.reload.end_date).to be_nil
      expect(@professor.affiliations.reload.count).to eq(1)
    end
  end

  it "recusa duas filiações novas que se cruzam no mesmo envio" do
    atualizar_professor([
      filiacao(@uff, Date.new(2015, 1, 1), Date.new(2020, 1, 1)),
      filiacao(@outra, Date.new(2018, 1, 1), nil)
    ])

    expect(@professor.affiliations.reload).to be_empty
  end

  # A mesma reprodução do subform de Nível: data inconvertível numa linha nova
  # não pode virar período em aberto. Aqui, a entrada que nenhum parser
  # entende; as que o cast entende e o date_picker não ficam no bloco abaixo.
  it "não acrescenta a filiação com término inconvertível como aberta" do
    atualizar_professor([
      filiacao(@uff, Date.new(2015, 1, 1), nil).merge(end_date: "banana")
    ])

    expect(@professor.affiliations.reload).to be_empty
  end

  # A revalidação da linha limpa o :invalid do date_picker, e o término que
  # ele não entende chegaria nil: na linha nova gravaria filiação aberta, e na
  # existente reabriria a encerrada. O active_scaffold_date_picker_raw_value.rb
  # entrega o texto ao modelo, e o cast de date recusa o dia que não existe
  # ("31/02/2026"); o de datetime, que estas colunas já tiveram, o empurrava
  # para 03/03/2026, data que ninguém digitou. Para os formatos que só divergem
  # na grafia, gravar o dia digitado atende tanto quanto recusar.
  describe "término que o date_picker não entende" do
    { "31/02/2026" => nil, "15.03.2024" => Date.new(2024, 3, 15), "2024-03-15" => Date.new(2024, 3, 15) }
      .each do |entrada, dia_digitado|
        it "não acrescenta a filiação como aberta: #{entrada.inspect}" do
          atualizar_professor([
            filiacao(@uff, Date.new(2015, 1, 1), nil).merge(end_date: entrada)
          ])

          gravadas = @professor.affiliations.reload.map { |f| f.end_date&.to_date }
          expect([[], [dia_digitado].compact]).to include(gravadas)
        end

        it "não reabre a filiação encerrada: #{entrada.inspect}" do
          encerrada = FactoryBot.create(
            :affiliation, professor: @professor, institution: @uff,
            start_date: Time.zone.local(2015, 1, 1), end_date: Time.zone.local(2020, 1, 1)
          )
          atualizar_professor([
            filiacao(@uff, Date.new(2015, 1, 1), nil, id: encerrada.id).merge(end_date: entrada)
          ])

          expect([Date.new(2020, 1, 1), dia_digitado].compact).to include(encerrada.reload.end_date&.to_date)
        end
      end
  end
end
