# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Template ERB (e Ruby, no campo de formula) chega a eval, entao nao pode nascer
# pela tela; o legado so continua salvavel se um template IGUAL ja existiu no
# historico do registro. Quem guarda esse historico e o paper_trail, e a
# validacao anda por ele com paper_trail.previous_version. Os specs de cada
# modelo so cobriam o registro novo, sem historico, e o laco nunca rodava
# (#720): um update do paper_trail que mudasse o reify passaria verde -- e o
# efeito seria travar a edicao de todo template legado, ou soltar ERB novo.
#
# A comparacao ignora caixa e acento (I18n.transliterate + downcase).
#
# A versao de criacao nao guarda estado anterior (o reify dela e nil), entao o
# legado que so tem essa versao nao acha nada no historico. A Notification
# escapa porque o after_create salva de novo e gera uma versao de update; nos
# outros modelos o legado so com a criacao e recusado mesmo sem mudar nada.
# Pela aplicacao esse estado nao se forma: as migrations que introduziram o
# template_type gravaram, com save_with_version, uma versao de update em cada
# registro que ja existia, e registro ERB novo a validacao nao deixa criar. O
# exemplo "so com a versao de criacao" monta o estado a mao e prende o
# comportamento do modelo como ele e.
RSpec.describe "Template ERB legado, pelo historico do paper_trail" do
  shared_examples "anda pelo historico" do
    # Criado e depois editado, os dois sem a validacao -- como um registro
    # anterior a ela. A edicao em outro campo e o que deixa no historico uma
    # versao com o template.
    def legado(texto)
      registro = nil
      modelo.disable_erb_validation! do
        registro = cria(texto)
        muda_outra_coisa(registro)
        registro.save!
      end
      registro
    end

    def reescreve_sem_validar(registro, texto)
      modelo.disable_erb_validation! { escreve(registro, texto); registro.save! }
    end

    it "aceita salvar o legado sem mexer no template" do
      registro = legado("<%= 1 + 1 %> Ação")
      registro.reload
      muda_outra_coisa(registro)

      expect(registro).to be_valid
    end

    it "aceita a mesma escrita com outra caixa e sem acento" do
      registro = legado("<%= 1 + 1 %> Ação")
      registro.reload
      escreve(registro, "<%= 1 + 1 %> ACAO")

      expect(registro).to be_valid
    end

    it "recusa template ERB que o historico nao tem" do
      registro = legado("<%= 1 + 1 %> Ação")
      registro.reload
      escreve(registro, "<%= 2 + 2 %> Ação")

      expect(registro).not_to be_valid
      expect(registro.errors.details[atributo_do_erro].map { _1[:error] })
        .to include(:cannot_create_new_erb_template)
    end

    it "so com a versao de criacao, segue o que o modelo faz hoje" do
      registro = nil
      modelo.disable_erb_validation! { registro = cria("<%= 1 + 1 %> Ação") }
      registro.reload
      muda_outra_coisa(registro)

      expect(registro.valid?).to eq(aceita_so_com_criacao)
    end

    it "aceita voltar a um template de duas versoes atras" do
      registro = legado("<%= 1 + 1 %> primeira")
      reescreve_sem_validar(registro, "<%= 1 + 1 %> segunda")
      registro.reload
      escreve(registro, "<%= 1 + 1 %> primeira")

      expect(registro).to be_valid
    end
  end

  describe Notification do
    let(:modelo) { Notification }
    let(:aceita_so_com_criacao) { true }
    let(:atributo_do_erro) { :body_template }
    def cria(texto)
      FactoryBot.create(:notification, template_type: Notification::ERB, body_template: texto)
    end
    def escreve(registro, texto) = registro.body_template = texto
    def muda_outra_coisa(registro) = registro.title = "outro titulo"

    include_examples "anda pelo historico"
  end

  describe EmailTemplate do
    let(:modelo) { EmailTemplate }
    let(:aceita_so_com_criacao) { false }
    let(:atributo_do_erro) { :body }
    def cria(texto)
      FactoryBot.create(:email_template, template_type: EmailTemplate::ERB, body: texto)
    end
    def escreve(registro, texto) = registro.body = texto
    # to, subject e body entram na comparacao; o nome nao.
    def muda_outra_coisa(registro) = registro.name = "#{registro.name}x"

    include_examples "anda pelo historico"
  end

  describe Assertion do
    let(:modelo) { Assertion }
    let(:aceita_so_com_criacao) { false }
    let(:atributo_do_erro) { :assertion_template }
    def cria(texto)
      Assertion.create!(
        name: "Declaracao", query: FactoryBot.create(:query),
        template_type: Assertion::ERB, assertion_template: texto
      )
    end
    def escreve(registro, texto) = registro.assertion_template = texto
    def muda_outra_coisa(registro) = registro.name = "Outra declaracao"

    include_examples "anda pelo historico"
  end

  describe Admissions::FormField do
    let(:modelo) { Admissions::FormField }
    let(:aceita_so_com_criacao) { false }
    let(:atributo_do_erro) { :base }
    def configuracao(texto) = JSON.dump(template_type: "ERB", code: texto)
    def cria(texto)
      FactoryBot.create(
        :form_field, field_type: Admissions::FormField::CODE,
        configuration: configuracao(texto),
        form_template: FactoryBot.create(
          :form_template, template_type: Admissions::FormTemplate::CONSOLIDATION_FORM
        )
      )
    end
    def escreve(registro, texto) = registro.configuration = configuracao(texto)
    def muda_outra_coisa(registro) = registro.name = "Outro campo"

    include_examples "anda pelo historico"
  end
end
