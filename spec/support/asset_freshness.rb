# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Um build em public/assets sombreia app/assets em QUALQUER ambiente: o
# sprockets-rails resolve pelo manifesto antes de cair na compilacao viva. Se o
# build estiver atrasado, os feature specs abrem o navegador contra o JavaScript
# de outro dia -- e passam, afirmando sobre codigo que nao executaram. E o pior
# tipo de falha: verde silencioso. Ja aconteceu de uma regressao que derrubava a
# tela inteira sobreviver a suite local e a tres rodadas de CI.
#
# No CI o diretorio nao existe (e gitignored), entao la o sprockets sempre
# compila do fonte e nada disto se aplica -- o defeito e exclusivamente local.
#
# A checagem roda antes de o Rails subir, em rails_helper.rb. Depois do boot o
# manifesto ja esta em memoria, e recompilar nao mudaria o que a rodada serve.
module AssetFreshness
  MANIFEST_GLOB = "public/assets/.sprockets-manifest-*.json"

  # node_modules tambem esta em config.assets.paths, mas fica de fora: sao
  # milhares de arquivos, e o que muda ali vem de package.json, que raramente
  # muda sozinho.
  SOURCE_GLOBS = ["app/assets/**/*", "vendor/assets/**/*"].freeze

  class << self
    # Roda antes do boot, entao Rails.root ainda nao existe: a raiz vem do
    # caminho deste arquivo.
    def recompile_if_stale!(root = File.expand_path("../..", __dir__))
      root = Pathname.new(root)
      manifest = newest_manifest(root)
      # Sem build local nao ha o que sombrear: o sprockets compila do fonte.
      return if manifest.nil?

      newest = newest_source(root)
      return if newest.nil? || File.mtime(manifest) >= File.mtime(newest)

      puts "[assets] public/assets esta atrasado em relacao a " \
           "#{Pathname.new(newest).relative_path_from(root)}; recompilando"
      recompile!(root)
    end

    private
      def newest_manifest(root)
        Dir[root.join(MANIFEST_GLOB)].max_by { |file| File.mtime(file) }
      end

      def newest_source(root)
        SOURCE_GLOBS
          .flat_map { |glob| Dir[root.join(glob)] }
          .reject { |path| File.directory?(path) }
          .max_by { |path| File.mtime(path) }
      end

      def recompile!(root)
        ok = system(
          { "RAILS_ENV" => "test" },
          "bundle", "exec", "rake", "assets:precompile",
          chdir: root.to_s, out: File::NULL
        )
        return if ok

        abort(
          "[assets] falha ao recompilar. Rode " \
          "`RAILS_ENV=test bundle exec rake assets:precompile` e veja o erro; " \
          "sem isso os feature specs rodam contra o build antigo."
        )
      end
  end
end
