# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# A rotina limpa o cache pelos uploaders do SAPOS, e nao pelo
# CarrierWave.clean_cached_files!, porque eles mudam o root (ver o comentario na
# rake). Ela depende do formato do id de cache do carrierwave -- o tempo vem do
# nome do diretorio --, que nenhum exemplo exercitava (#720). Os uploaders sao
# apontados para um diretorio temporario: o cache real do checkout nao entra.
RSpec.describe "maintenance:clean_upload_cache", type: :task do
  before(:all) do
    require "rake"
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) do
    Rake::Task["maintenance:clean_upload_cache"].reenable
    # Sem Dir.mktmpdir: o nome dele (data-pid-sufixo) pode casar com o padrao do
    # id de cache, que o clean_cache! procura no caminho INTEIRO, e entao tudo
    # que estiver abaixo parece vencido desde 1970. O root de producao nao tem
    # numero com hifen.
    @raiz = Rails.root.join("tmp", "cache_sapos_#{SecureRandom.alphanumeric(12)}").to_s
    FileUtils.mkdir_p(@raiz)
    [FormFileUploader, ImageUploader].each do |uploader|
      allow_any_instance_of(uploader).to receive(:root).and_return(@raiz)
    end
  end

  after(:each) { FileUtils.rm_rf(@raiz) }

  def entrada_de_cache(idade)
    nome = "#{(Time.now.utc - idade).to_i}-123456789-0001-0042"
    caminho = File.join(@raiz, FormFileUploader.new.cache_dir, nome)
    FileUtils.mkdir_p(caminho)
    File.write(File.join(caminho, "arquivo.pdf"), "conteudo")
    caminho
  end

  it "apaga a entrada com mais de 24 horas e poupa a recente" do
    velha = entrada_de_cache(25.hours)
    nova = entrada_de_cache(1.hour)

    Rake::Task["maintenance:clean_upload_cache"].invoke

    expect(File).not_to exist(velha)
    expect(File).to exist(nova)
  end

  it "nao toca no que nao tem o formato do id de cache" do
    estranho = File.join(@raiz, FormFileUploader.new.cache_dir, "nao-e-cache")
    FileUtils.mkdir_p(estranho)

    Rake::Task["maintenance:clean_upload_cache"].invoke

    expect(File).to exist(estranho)
  end
end
