# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Relatórios do processo seletivo (#681): a tabela que a configuração de
# relatório monta a partir dos grupos (dados principais, cartas, fases, ranking,
# campos, consolidação), com filtro, ordenação e as três formas de linha que o
# PDF, a planilha e a tela consomem.
RSpec.describe Admissions::AdmissionReportConfig, "montagem da tabela", type: :model do
  before(:each) do
    @template = create_admission_template("Inscrição", {
      "nota" => Admissions::FormField::NUMBER,
      "anexo" => Admissions::FormField::FILE,
      "grupo" => Admissions::FormField::GROUP,
      "aviso" => Admissions::FormField::HTML,
    })
    @letter_template = create_admission_template(
      "Carta", { "carta_texto" => Admissions::FormField::TEXT },
      template_type: Admissions::FormTemplate::RECOMMENDATION_LETTER
    )
    # O mínimo de cartas entra depois das inscrições: com ele desde o início, a
    # candidatura enviada sem carta seria recusada na criação.
    @process = create_closed_admission_process(
      @template, simple_url: "relatorio-spec", letter_template: @letter_template
    )
    @phase1 = add_phase(
      @process, 1, name: "Análise",
      shared_form: create_admission_template("Ficha", { "obs" => Admissions::FormField::STRING }),
      member_form: create_admission_template("Parecer", { "parecer" => Admissions::FormField::STRING }),
      candidate_form: create_admission_template("Complemento", { "extra" => Admissions::FormField::STRING }),
      consolidation_form: create_consolidation_template("Consolidação", { "um" => code_field("1") })
    )
    @phase2 = add_phase(
      @process, 2, name: "Entrevista",
      shared_form: create_admission_template("Entrevista", { "nota_entrevista" => Admissions::FormField::NUMBER })
    )
    @reviewer = professor_user("relatorio-reviewer@ic.uff.br")
    @silent = professor_user("relatorio-silent@ic.uff.br")

    @ana = create_application(@process, name: "Ana", fields: {
      "nota" => "8",
      "anexo" => { file: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png") },
    }, admission_phase: @phase2)
    first_letter = @ana.letter_requests.create!(name: "Prof. A", email: "a@example.com", telephone: "1111")
    first_letter.filled_form.update!(is_filled: true)
    fill_fields(first_letter.filled_form, { "carta_texto" => "Recomendo." })
    @ana.letter_requests.create!(name: "Prof. B", email: "b@example.com")
    create_phase_result(@ana, @phase1, Admissions::AdmissionPhaseResult::SHARED, fields: { "obs" => "ok" })
    create_phase_result(@ana, @phase1, Admissions::AdmissionPhaseResult::CONSOLIDATION, fields: { "um" => "1" })
    create_evaluation(@ana, @phase1, @reviewer, fields: { "parecer" => "forte" })
    [@reviewer, @silent].each do |user|
      FactoryBot.create(
        :admission_pendency, admission_application: @ana, admission_phase: @phase1,
        mode: Admissions::AdmissionPendency::MEMBER, user: user, status: Admissions::AdmissionPendency::OK
      )
    end

    @bia = create_application(@process, name: "Bia", fields: { "nota" => "6" })
    @caio = create_application(@process, name: "Caio", filled: false)
    @process.update!(min_letters: 1, max_letters: 2)

    @ranking = FactoryBot.create(:ranking_config, name: "Geral", default_column: "nota")
    FactoryBot.create(:admission_process_ranking, admission_process: @process, ranking_config: @ranking, order: 1)
    result = Admissions::AdmissionRankingResult.create!(admission_application: @ana, ranking_config: @ranking)
    result.filled_position.update!(value: "1")
    result.filled_machine.update!(value: "AC")
    result.filled_form.update!(is_filled: true)
  end

  def headers(config)
    config[:header].map { |column| column[:header] }
  end

  def section_titles(config)
    config[:groups].flat_map { |group| group.sections.map { |section| section[:title] } }
  end

  # As linhas saem dos objetos que a própria tabela carregou: é neles que a
  # consolidação do relatório fica guardada (non_persistent), como nas views.
  def in_table(config, application)
    config[:applications].find { |candidate| candidate == application }
  end

  def row_values(report, config, application, **options)
    report.prepare_row(config, in_table(config, application), **options).map { |element| element[:value] }
  end

  describe "#init_default e #init_simple" do
    it "montam os grupos padrão sem gravar nada" do
      report = Admissions::AdmissionReportConfig.new.init_default
      expect(report.groups.map(&:mode)).to eq([
        Admissions::AdmissionReportGroup::MAIN, Admissions::AdmissionReportGroup::MAIN_LETTER,
        Admissions::AdmissionReportGroup::CONSOLIDATION, Admissions::AdmissionReportGroup::RANKING,
        Admissions::AdmissionReportGroup::PHASE_REVERSE, Admissions::AdmissionReportGroup::FIELD,
        Admissions::AdmissionReportGroup::LETTER,
      ])
      expect(report.groups.select(&:in_simple).size).to eq(2)
      expect(report.ranking_columns.map(&:name)).to eq(["name"])
      expect(report.group_column_tabular).to eq(Admissions::AdmissionReportConfig::MERGE)
      expect(report).to be_new_record

      simple = Admissions::AdmissionReportConfig.new.init_simple
      expect(simple.groups.size).to eq(2)
    end
  end

  describe "#prepare_table com a configuração padrão" do
    before(:each) do
      @report = Admissions::AdmissionReportConfig.new.init_default
      @config = @report.prepare_table(@process)
      @config[:base_url] = "http://sapos.test"
    end

    it "lista só as inscrições enviadas, em ordem de nome" do
      expect(@config[:applications]).to eq([@ana, @bia])
    end

    it "monta o cabeçalho com dados principais, cartas, fases em ordem inversa, campos e cartas" do
      expect(headers(@config)).to eq([
        Admissions::AdmissionApplication.record_i18n_attr("token"),
        Admissions::AdmissionApplication.record_i18n_attr("name"),
        Admissions::AdmissionApplication.record_i18n_attr("email"),
        Admissions::AdmissionApplication.record_i18n_attr("requested_letters"),
        Admissions::AdmissionApplication.record_i18n_attr("filled_letters"),
        "#{Admissions::RankingConfig::POSITION}/Geral", "#{Admissions::RankingConfig::MACHINE}/Geral",
        "um", "parecer", "obs",
        "nota", "anexo",
        Admissions::LetterRequest.record_i18n_attr("name"),
        Admissions::LetterRequest.record_i18n_attr("email"),
        Admissions::LetterRequest.record_i18n_attr("telephone"),
        "carta_texto",
        Admissions::LetterRequest.record_i18n_attr("name"),
        Admissions::LetterRequest.record_i18n_attr("email"),
        Admissions::LetterRequest.record_i18n_attr("telephone"),
        "carta_texto",
      ])
    end

    it "esconde as seções de fase sem resposta e o membro que não avaliou" do
      titles = section_titles(@config)
      expect(titles).to include("Análise - #{Admissions::AdmissionPhaseResult::CONSOLIDATION}")
      expect(titles).to include("Análise - #{@reviewer.name}")
      expect(titles).to include("Análise - #{Admissions::AdmissionPhaseResult::SHARED}")
      expect(titles).not_to include("Análise - #{@silent.name}")
      expect(titles).not_to include("Análise - #{Admissions::AdmissionPhaseResult::CANDIDATE}")
      expect(titles).not_to include("Entrevista - #{Admissions::AdmissionPhaseResult::SHARED}")
    end

    it "preenche a linha de quem tem tudo e deixa em branco a de quem não tem" do
      ana_row = row_values(@report, @config, @ana)
      expect(ana_row[0..4]).to eq([@ana.token, "Ana", @ana.email, 2, 1])
      expect(ana_row[5..9]).to eq(["1", "AC", "1", "forte", "ok"])
      expect(ana_row[10]).to eq("8")
      expect(ana_row[11]).to eq("http://sapos.test/files/#{@ana.filled_form.fields.find { |field| field.file.present? }.file.medium_hash}")
      expect(ana_row[12..15]).to eq(["Prof. A", "a@example.com", "1111", "Recomendo."])
      expect(ana_row[16..19]).to eq(["Prof. B", "b@example.com", nil, ""])

      bia_row = row_values(@report, @config, @bia)
      expect(bia_row[3..4]).to eq([0, 0])
      expect(bia_row[5..9]).to eq(["<não encontrado>"] * 5)
      # Bia nunca preencheu o anexo: o campo não existe no formulário dela.
      expect(bia_row[10..11]).to eq(["6", "<não encontrado>"])
      expect(bia_row[12..19]).to eq([""] * 8)
    end

    it "prepare_row simple: só os grupos marcados para o relatório resumido" do
      expect(row_values(@report, @config, @ana, simple: true)).to eq([@ana.token, "Ana", @ana.email, 2, 1])
    end

    it "prepare_excel_row transforma arquivo em fórmula de link, sem escapar só ela" do
      result = @report.prepare_excel_row(@config, in_table(@config, @ana))
      hash = @ana.filled_form.fields.find { |field| field.file.present? }.file.medium_hash
      url = "http://sapos.test/files/#{hash}"
      expect(result[:row][11]).to eq("=HYPERLINK(\"#{url}\", \"#{url}\")")
      expect(result[:escape_formulas][11]).to be false
      expect(result[:escape_formulas].count(false)).to eq(1)
      expect(result[:row][1]).to eq("Ana")
    end

    it "prepare_html_row transforma arquivo em âncora" do
      row = @report.prepare_html_row(@config, in_table(@config, @ana))
      expect(row[11][:value]).to include("<a href=\"http://sapos.test/files/")
      expect(row[11][:value]).to include("user.png")
      expect(row[11][:value]).to be_html_safe
      expect(row[10][:value]).to eq("8")
    end
  end

  describe "#prepare_table com opções" do
    def report_with(groups, **attrs)
      report = Admissions::AdmissionReportConfig.new(
        { group_column_tabular: Admissions::AdmissionReportConfig::MERGE, hide_empty_sections: true }.merge(attrs)
      )
      groups.each_with_index do |(mode, operation, columns), index|
        group = report.groups.build(
          order: index + 1, mode: mode, operation: operation || Admissions::AdmissionReportGroup::EXCLUDE,
          pdf_format: Admissions::AdmissionReportGroup::TABLE
        )
        (columns || []).each_with_index do |name, column_index|
          group.columns.build(name: name, order: column_index + 1)
        end
      end
      report
    end

    it "inclui as inscrições não enviadas com show_partial_candidates" do
      report = report_with([[Admissions::AdmissionReportGroup::MAIN]], show_partial_candidates: true)
      expect(report.prepare_table(@process)[:applications]).to contain_exactly(@ana, @bia, @caio)
    end

    it "filtra pela condição do relatório" do
      report = report_with([[Admissions::AdmissionReportGroup::MAIN]])
      report.form_condition = field_condition("nota", Admissions::FormCondition::GE, "7")
      expect(report.prepare_table(@process)[:applications]).to eq([@ana])
    end

    it "ordena pelas colunas de ranking e descarta quem não tem a coluna" do
      report = report_with([[Admissions::AdmissionReportGroup::MAIN]])
      report.ranking_columns.build(name: "nota", order: Admissions::RankingColumn::DESC)
      expect(report.prepare_table(@process)[:applications]).to eq([@ana, @bia])
      report.ranking_columns.build(name: "obs", order: Admissions::RankingColumn::ASC)
      expect(report.prepare_table(@process)[:applications]).to eq([@ana])
    end

    it "consolida um template do relatório por candidato e o mostra como seção" do
      consolidation = create_consolidation_template("Relatório", {
        "dobro" => code_field("{{ fields.nota | times: 2 }}"),
      })
      report = report_with([[Admissions::AdmissionReportGroup::CONSOLIDATION]], form_template: consolidation)
      config = report.prepare_table(@process)

      expect(headers(config)).to eq(["dobro"])
      expect(section_titles(config)).to eq(["Relatório"])
      expect(row_values(report, config, @ana)).to eq(["16"])
      expect(row_values(report, config, @bia)).to eq(["12"])
    end

    it "pula a seção de consolidação sem template e sem candidato consolidado" do
      report = report_with([[Admissions::AdmissionReportGroup::CONSOLIDATION]])
      expect(headers(report.prepare_table(@process))).to eq([])
    end

    it "mostra todas as seções de fase com hide_empty_sections desligado, em ordem direta" do
      report = report_with([[Admissions::AdmissionReportGroup::PHASE]], hide_empty_sections: false)
      config = report.prepare_table(@process)
      expect(section_titles(config)).to eq([
        "Análise - #{Admissions::AdmissionPhaseResult::SHARED}",
        "Análise - #{@reviewer.name}",
        "Análise - #{@silent.name}",
        "Análise - #{Admissions::AdmissionPhaseResult::CANDIDATE}",
        "Análise - #{Admissions::AdmissionPhaseResult::CONSOLIDATION}",
        "Entrevista - #{Admissions::AdmissionPhaseResult::SHARED}",
      ])
      expect(row_values(report, config, @ana)).to eq(["ok", "forte", "<não encontrado>", "<não encontrado>", "1", "<não encontrado>"])
    end

    it "omite as avaliações individuais no modo sem comitê" do
      report = report_with([[Admissions::AdmissionReportGroup::PHASE_WITHOUT_COMMITTEE_REVERSE]], hide_empty_sections: false)
      titles = section_titles(report.prepare_table(@process))
      expect(titles.first).to eq("Entrevista - #{Admissions::AdmissionPhaseResult::SHARED}")
      expect(titles).not_to include("Análise - #{@reviewer.name}")
      expect(titles.size).to eq(4)
    end

    it "com operação incluir, traz só as colunas nomeadas, aceitando prefixo de fase e de ranking" do
      report = report_with([
        [Admissions::AdmissionReportGroup::PHASE, Admissions::AdmissionReportGroup::INCLUDE, ["1.obs", "Análise.member.parecer"]],
        [Admissions::AdmissionReportGroup::RANKING, Admissions::AdmissionReportGroup::INCLUDE, ["Geral.#{Admissions::RankingConfig::POSITION}"]],
        [Admissions::AdmissionReportGroup::FIELD, Admissions::AdmissionReportGroup::INCLUDE, ["nota", "inexistente"]],
        [Admissions::AdmissionReportGroup::LETTER, Admissions::AdmissionReportGroup::INCLUDE, ["carta_texto", Admissions::LetterRequest.record_i18n_attr("status")]],
        [Admissions::AdmissionReportGroup::MAIN, Admissions::AdmissionReportGroup::INCLUDE, ["name"]],
      ])
      config = report.prepare_table(@process)
      expect(headers(config)).to eq([
        "obs", "parecer", "#{Admissions::RankingConfig::POSITION}/Geral", "nota",
        "carta_texto", Admissions::LetterRequest.record_i18n_attr("status"),
        "carta_texto", Admissions::LetterRequest.record_i18n_attr("status"),
        Admissions::AdmissionApplication.record_i18n_attr("name"),
      ])
      expect(row_values(report, config, @ana)).to eq([
        "ok", "forte", "1", "8",
        "Recomendo.", Admissions::LetterRequest::RECEIVED, "", Admissions::LetterRequest::WAITING, "Ana",
      ])
    end

    it "com operação excluir, tira as colunas nomeadas por qualquer dos nomes" do
      report = report_with([
        [Admissions::AdmissionReportGroup::FIELD, Admissions::AdmissionReportGroup::EXCLUDE, ["anexo"]],
        [Admissions::AdmissionReportGroup::PHASE, Admissions::AdmissionReportGroup::EXCLUDE, ["2.nota_entrevista", "parecer"]],
        [Admissions::AdmissionReportGroup::RANKING, Admissions::AdmissionReportGroup::EXCLUDE, [Admissions::RankingConfig::MACHINE]],
        [Admissions::AdmissionReportGroup::MAIN_ANONYMOUS],
      ], hide_empty_sections: false)
      config = report.prepare_table(@process)
      expect(headers(config)).to eq([
        "nota", "obs", "extra", "um",
        "#{Admissions::RankingConfig::POSITION}/Geral",
        Admissions::AdmissionApplication.record_i18n_attr("identifier"),
      ])
      expect(row_values(report, config, @ana).last).to eq(@ana.identifier)
    end

    it "no modo coluna, separa cada seção com uma coluna de título, exceto a principal" do
      report = report_with(
        [[Admissions::AdmissionReportGroup::MAIN], [Admissions::AdmissionReportGroup::FIELD]],
        group_column_tabular: Admissions::AdmissionReportConfig::COLUMN
      )
      config = report.prepare_table(@process)
      separators = config[:header].select { |column| column[:mode] == :group_column }
      expect(separators.map { |column| column[:header] }).to eq([Admissions::AdmissionReportGroup::FIELD])
      row = report.prepare_row(config, in_table(config, @ana))
      expect(row.size).to eq(config[:header].size)
      expect(row[3][:column][:mode]).to eq(:group_column)
      expect(row[3][:value]).to eq("")
    end

    it "não monta seção de cartas nem de dados de carta em processo sem cartas" do
      @process.update!(min_letters: nil, max_letters: nil, letter_template: nil)
      report = report_with([[Admissions::AdmissionReportGroup::LETTER], [Admissions::AdmissionReportGroup::MAIN_LETTER]])
      expect(headers(report.prepare_table(@process))).to eq([])
    end

    it "esconde a seção de campos e a de ranking quando não há dado" do
      Admissions::AdmissionRankingResult.delete_all
      @ana.filled_form.update!(is_filled: false)
      @bia.filled_form.update!(is_filled: false)
      report = report_with([[Admissions::AdmissionReportGroup::FIELD], [Admissions::AdmissionReportGroup::RANKING]], show_partial_candidates: true)
      expect(headers(report.prepare_table(@process))).to eq([])
    end
  end
end
