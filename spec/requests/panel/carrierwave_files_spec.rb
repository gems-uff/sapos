# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Regressao do "Coletor de lixo" do Painel (issue #560), cobrindo o ultimo
# comentario do mantenedor:
#
#   Ponto 1 (paginacao lenta): a listagem le um snapshot persistido em
#     carrierwave_orphan_files e NAO re-roda o Mark-and-Sweep a cada clique; a
#     re-varredura fica num botao (run_mark_and_sweep).
#   Ponto 2 (delete_all estourava rota): delete_all apaga os orfaos e as linhas de
#     rastreio e redireciona sem NameError.
#   Ponto 3 ("apaguei e a contagem nao mudou"): um carrier_wave_file so vira orfao
#     quando a ULTIMA referencia sai -- arquivos sao de-duplicados por conteudo.
#
# Todos os arquivos de teste sao criados por conteudo distinto (para nao deduplicar
# sem querer) via foto de Student, o caminho de upload mais simples.
RSpec.describe "Painel :: Coletor de lixo", type: :request do
  def ar_file
    CarrierWave::Storage::ActiveRecord::ActiveRecordFile
  end

  # Upload .png com conteudo distinto por chamada -> medium_hash distinto.
  def png_upload(tag)
    path = File.join(Dir.mktmpdir, "f-#{tag.to_s.parameterize}.png")
    File.binwrite(path, "PNGDATA-#{tag}")
    Rack::Test::UploadedFile.new(path, "image/png")
  end

  # Cria um carrier_wave_file ORFAO (sem nenhuma referencia) e devolve o registro.
  # update_column nao dispara CarrierWaveFileCleanup, entao a linha sobrevive orfa.
  def create_orphan_file(tag)
    student = FactoryBot.create(:student)
    student.photo = png_upload("orfao-#{tag}")
    student.save!
    file = ar_file.find_by(medium_hash: student.read_attribute(:photo))
    student.update_column(:photo, nil)
    file.reload
  end

  before(:each) do |example|
    @admin = create_confirmed_user(
      [FactoryBot.create(:role_administrador)], "panel_admin@ic.uff.br"
    )
    @enable_panel = FactoryBot.create(
      :custom_variable, variable: "enable_panel", value: "yes"
    )
    # O exemplo de autorizacao entra com um usuario sem privilegios, entao nao
    # assinamos o admin nele -- trocar de usuario no meio do exemplo e fragil.
    sign_in(@admin) unless example.metadata[:sem_admin]
  end

  describe "portao do painel (enable_panel)" do
    it "redireciona para as configuracoes quando o painel esta desligado" do
      @enable_panel.update!(value: "no")

      get carrierwave_files_path

      expect(response).to redirect_to(custom_variables_path)
    end

    it "abre a listagem quando o painel esta ligado" do
      get carrierwave_files_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST run_mark_and_sweep" do
    it "marca so os arquivos orfaos e ignora os referenciados" do
      orphan = create_orphan_file("a")
      alive = FactoryBot.create(:student)
      alive.photo = png_upload("vivo")
      alive.save!
      alive_file = ar_file.find_by(medium_hash: alive.read_attribute(:photo))

      post run_mark_and_sweep_carrierwave_files_path

      expect(response).to redirect_to(carrierwave_files_path)
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: orphan.id)).to exist
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: alive_file.id))
        .not_to exist
    end

    it "substitui o snapshot a cada execucao, sem acumular" do
      create_orphan_file("b")

      post run_mark_and_sweep_carrierwave_files_path
      first_count = CarrierwaveOrphanFile.count
      expect(first_count).to be >= 1

      post run_mark_and_sweep_carrierwave_files_path

      expect(CarrierwaveOrphanFile.count).to eq(first_count)
    end
  end

  # Ponto 1: prova que a paginacao le o snapshot e NAO re-varre -- um orfao criado
  # depois da ultima varredura so aparece quando se re-roda o Mark-and-Sweep.
  describe "a listagem le o snapshot e nao re-roda a varredura (ponto 1)" do
    it "so mostra o que estava na ultima varredura" do
      post run_mark_and_sweep_carrierwave_files_path
      expect(CarrierwaveOrphanFile.count).to eq(0)

      orphan = create_orphan_file("c")

      get carrierwave_files_path
      expect(response).to have_http_status(:ok)
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: orphan.id))
        .not_to exist

      post run_mark_and_sweep_carrierwave_files_path
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: orphan.id)).to exist
    end
  end

  # Ponto 2: o crash era um redirect para rota inexistente; hoje redireciona certo.
  describe "POST delete_all (ponto 2)" do
    it "apaga os orfaos e as linhas de rastreio e redireciona sem estourar" do
      orphan = create_orphan_file("d")
      post run_mark_and_sweep_carrierwave_files_path
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: orphan.id)).to exist

      expect { post delete_all_carrierwave_files_path }
        .to change { ar_file.where(id: orphan.id).count }.from(1).to(0)

      expect(response).to redirect_to(carrierwave_files_path)
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: orphan.id))
        .not_to exist
    end

    it "redireciona sem erro quando nao ha nada para apagar" do
      post delete_all_carrierwave_files_path

      expect(response).to redirect_to(carrierwave_files_path)
    end
  end

  describe "DELETE de um unico arquivo (do_destroy)" do
    it "apaga o arquivo e remove sua linha de rastreio" do
      orphan = create_orphan_file("e")
      post run_mark_and_sweep_carrierwave_files_path

      expect { delete carrierwave_file_path(orphan) }
        .to change { ar_file.where(id: orphan.id).count }.from(1).to(0)

      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: orphan.id))
        .not_to exist
    end
  end

  describe "autorizacao" do
    it "nega as acoes custom para quem nao gerencia o painel", :sem_admin do
      # Papel sem privilegios e sem exigir associacao (professor/aluno exigem).
      sign_in create_confirmed_user(
        [FactoryBot.create(:role_desconhecido)], "sem_acesso@ic.uff.br"
      )

      post run_mark_and_sweep_carrierwave_files_path

      # CanCan::AccessDenied nao tem mapeamento em rescue_responses, entao aparece
      # como 500 -- a pagina que o SAPOS mostra a quem e barrado (mesmo padrao de
      # student_enrollment_spec).
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  # Ponto 3: "apaguei 4 arquivos e o numero de tuplas nao mudou. Era para ser
  # assim?" -- sim, quando o arquivo tem mais de um dono. Os dois exemplos abaixo
  # fixam o comportamento atual em SQLite.
  describe "arquivo compartilhado e contagem de tuplas (ponto 3)" do
    it "remove a linha ao apagar pela aplicacao quando era a unica referencia" do
      student = FactoryBot.create(:student)
      student.photo = png_upload("dono-unico")
      student.save!
      hash = student.read_attribute(:photo)
      expect(ar_file.where(medium_hash: hash).count).to eq(1)

      student.update!(photo: nil)

      expect(ar_file.where(medium_hash: hash).count).to eq(0)
    end

    it "sobrevive e nao vira orfao enquanto outra referencia existir" do
      owner1 = FactoryBot.create(:student)
      owner1.photo = png_upload("compartilhado")
      owner1.save!
      hash = owner1.read_attribute(:photo)
      file = ar_file.find_by(medium_hash: hash)

      # Segunda referencia ao MESMO hash (sem passar pelo uploader).
      owner2 = FactoryBot.create(:student)
      owner2.update_column(:photo, hash)

      # Tira a primeira referencia sem disparar o cleanup: a linha continua.
      owner1.update_column(:photo, nil)

      Panel::CarrierwaveFilesHelper.run_mark_and_sweep!
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: file.id)).not_to exist

      # So quando a ULTIMA referencia sai o arquivo vira orfao.
      owner2.update_column(:photo, nil)
      Panel::CarrierwaveFilesHelper.run_mark_and_sweep!
      expect(CarrierwaveOrphanFile.where(carrierwave_file_id: file.id)).to exist
    end
  end

  # A coluna "Modelo Original" e so um rotulo de exibicao, descoberto cruzando com
  # a tabela versions. Exemplo deterministico do cruzamento.
  describe "atribuicao do modelo original via versions" do
    it "identifica o item_type pela version que contem o medium_hash" do
      orphan = create_orphan_file("ver")
      Version.create!(
        item_type: "Student", item_id: 987, event: "update",
        object: "---\nphoto: #{orphan.medium_hash}\n"
      )

      version = Panel::CarrierwaveFilesHelper
        .find_version_for_carrierwave_file(orphan)

      expect(version).to be_present
      expect(version.item_type).to eq("Student")
    end
  end
end
