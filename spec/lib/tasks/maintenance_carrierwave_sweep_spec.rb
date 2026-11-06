# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Decisao do mantenedor (#560): o coletor roda toda noite como subtarefa propria
# do maintenance:run, alem do botao do painel. Sem isso, o espaco que os pontos
# de escrita deixam de liberar so volta quando alguem lembrar de abrir o painel.
RSpec.describe "maintenance:run", type: :task do
  before(:all) do
    require "rake"
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) { Rake::Task.tasks.each(&:reenable) }

  it "apaga a linha de carrier_wave_files sem dono" do
    orphan = CarrierWave::Storage::ActiveRecord::ActiveRecordFile.create!(
      medium_hash: "#{SecureRandom.hex(16)}.pdf", original_filename: "a.pdf",
      content_type: "application/pdf", size: 3, binary: "pdf"
    )
    orphan.update_columns(created_at: 2.hours.ago, updated_at: 2.hours.ago)

    Rake::Task["maintenance:run"].invoke

    expect(CarrierWave::Storage::ActiveRecord::ActiveRecordFile.where(id: orphan.id)).not_to exist
  end
end
