# From: https://stackoverflow.com/questions/29309324/how-to-test-csv-file-download-in-capybara-and-rspec
# frozen_string_literal: true

module DownloadHelpers
  # 5 s era apertado para gerar PDF num runner compartilhado, e o estouro vira
  # Timeout::Error sem contexto nenhum.
  TIMEOUT = 15
  PATH    = Rails.root.join("tmp/test_downloads")
  # Extensoes que o navegador usa enquanto o arquivo ainda esta sendo escrito.
  PARTIAL = [".part", ".crdownload"].freeze

  extend self

  def downloads
    Dir[PATH.join("*")].reject { |f| f.end_with?("downloads.html") }
  end

  def completed
    downloads.reject { |f| f.end_with?(*PARTIAL) }
  end

  # Nunca devolve um arquivo pela metade, mesmo que um .crdownload apareca entre
  # a espera e a leitura -- eram duas varreduras do diretorio, e nada ligava o
  # estado validado por uma ao estado observado pela outra.
  def download
    completed.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.1 until downloaded?
    end
    download
  end

  def downloaded?
    # File.size? devolve nil para arquivo vazio, e e assim que o nome que o
    # navegador reserva ANTES de escrever o .crdownload deixa de contar como
    # download pronto. Sem isso a espera retornava naquele instante -- existe um
    # arquivo, nao existe parcial -- e a asercao seguinte pegava o .crdownload.
    !downloading? && completed.any? { |f| File.size?(f) }
  end

  def downloading?
    downloads.any? { |f| f.end_with?(*PARTIAL) }
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end
end
