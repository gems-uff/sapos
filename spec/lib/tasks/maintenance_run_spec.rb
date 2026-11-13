# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O maintenance:run e o que o cron das instalacoes chama, e nada o invocava
# (#720): as subtarefas tem spec proprio, mas uma que saisse da lista do run
# deixaria de rodar em producao sem vermelho. Aqui as tres sao espionadas.
RSpec.describe "maintenance:run", type: :task do
  let(:subtarefas) do
    %w[
      maintenance:remove_expired_reports
      maintenance:clean_upload_cache
      maintenance:trigger_notifications
    ]
  end

  before(:all) do
    require "rake"
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before(:each) do
    Rake::Task["maintenance:run"].reenable
    @chamadas = []
    subtarefas.each do |nome|
      allow(Rake::Task[nome]).to receive(:invoke) { @chamadas << nome }
    end
  end

  it "invoca as tres subtarefas, nesta ordem" do
    Rake::Task["maintenance:run"].invoke

    expect(@chamadas).to eq(subtarefas)
  end

  it "registra o inicio e o fim no log" do
    allow(Rails.logger).to receive(:info).and_call_original

    Rake::Task["maintenance:run"].invoke

    expect(Rails.logger).to have_received(:info).with(/\[Maintenance\] .* - Starting maintenance tasks/)
    expect(Rails.logger).to have_received(:info).with(/\[Maintenance\] .* - Finished maintenance tasks/)
  end
end
