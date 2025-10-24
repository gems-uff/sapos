# From: https://stackoverflow.com/questions/29309324/how-to-test-csv-file-download-in-capybara-and-rspec
# frozen_string_literal: true

module DownloadHelpers
  TIMEOUT = 5
  PATH    = Rails.root.join("tmp/test_downloads")

  extend self

  def downloads
    Dir[PATH.join("*")]
  end

  def download
    downloads.first
  end

  def download_content
    wait_for_download
    File.read(download)
  end

  def wait_for_download
    Timeout.timeout(TIMEOUT) do
      sleep 0.1 until downloaded?
    end
  end

  def downloaded?
    !downloading? && downloads.any?
  end

  def downloading?
    downloads.any? { |f| f.end_with?(".part", ".crdownload") }
  end

  def clear_downloads
    FileUtils.rm_f(downloads)
  end
end
