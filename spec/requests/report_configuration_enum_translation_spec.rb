# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Guarda preemptiva do salto do active_scaffold para a serie 4.3 (#621).
#
# A 4.3.0 mudou como a gem traduz as opcoes de um form_ui :select/enum: passou a
# procurar o rotulo "nested in the pluralized name of the column". Ate a 4.2 o
# caminho era column.active_record_class.human_attribute_name(:chave), que resolve
# a chave achatada em activerecord.attributes.<modelo>.<chave> -- e e assim que o
# report_configuration.pt-BR.yml declara "Sem Assinatura"/"Manual"/"Codigo QR",
# direto sob report_configuration, sem aninhar em signature_types.
#
# Se a 4.3 tiver trocado esse caminho em vez de so acrescentar um fallback, a
# busca achatada para de resolver e o dropdown passa a mostrar o rotulo cru
# (a chave humanizada em ingles, "No signature", "Qr code"). Num sistema pt-BR
# isso e uma regressao visivel, e as telas de config de documento so tinham
# cobertura de caminho feliz que nao olha o texto das opcoes. Este exemplo olha.
#
# signature_type e o enum { no_signature: 0, manual: 1, qr_code: 2 }, renderizado
# como :select em report_configurations_controller.rb.
RSpec.describe "ReportConfiguration enum translation", type: :request do
  # Os rotulos pt-BR que report_configuration.pt-BR.yml declara para cada valor
  # do enum. Se a busca de traducao quebrar, nenhum deles aparece como texto de
  # opcao -- aparece a chave humanizada.
  def expected_labels
    ["Sem Assinatura", "Manual", "Código QR"]
  end

  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @admin = create_confirmed_user([@role_adm], "report_config_admin@ic.uff.br")
    sign_in @admin
  end

  # O texto exibido de cada opcao do select de signature_type. O value da opcao e
  # a chave do enum (no_signature, ...) e estaria no corpo de qualquer jeito;
  # quem denuncia a traducao e o texto. Levanta se o select nao for achado, para
  # o exemplo nao passar a toa quando a marcacao muda de lugar.
  def signature_type_option_texts
    node = Nokogiri::HTML(response.body)
      .at_css("select[name*='signature_type']")
    raise "formulario sem o select de signature_type" if node.nil?
    node.css("option").map { |o| o.text.strip }.reject(&:empty?)
  end

  describe "GET new" do
    it "renders the signature type options translated, not the raw enum keys" do
      get new_report_configuration_path

      expect(response).to have_http_status(:ok)
      expect(signature_type_option_texts).to include(*expected_labels)
    end
  end

  describe "GET edit" do
    it "renders the signature type options translated, not the raw enum keys" do
      # A factory nao preenche x/y/scale, que o modelo exige por presenca. scale
      # e decimal(10,8) -> so cabe ate 99.99999999 no MariaDB estrito; 1 basta, e
      # e o valor que o feature spec de report_configurations ja usa.
      record = FactoryBot.create(:report_configuration, scale: 1, x: 0, y: 0)

      get edit_report_configuration_path(record)

      expect(response).to have_http_status(:ok)
      expect(signature_type_option_texts).to include(*expected_labels)
    end
  end
end
