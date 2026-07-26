# SAPOS — instruções para agentes

Sistema de gestão de pós-graduação. Produção roda em Apache+Passenger sobre
MariaDB; a suíte de testes roda em SQLite. Versões de Ruby, Rails e gems vêm do
`Gemfile` e do `Gemfile.lock` — não as reproduza aqui.

## Documentação existente

Antes de escrever procedimento novo, consulte a [wiki](https://github.com/gems-uff/sapos/wiki):

- Instalação para desenvolvimento: `Quick-install` e `Explained-Quick-install-for-development`
- Instalação para produção: `Explained-quick-install-for-production`
- Atualização de release: `Upgrading-to-a-new-release`

Referencie essas páginas em vez de duplicá-las. Se algo estiver desatualizado,
corrija na wiki.

## Convenções de trabalho

- Uma issue, um ramo `issue_NNN`, sempre baseado na `main`. Detalhes do ciclo em
  `CONTRIBUTING.md`.
- **Exceção:** vulnerabilidade não ganha issue pública — enumerar o problema
  expõe o ataque antes da correção. Ramo direto da `main`, descrição genérica.
- Critério de pronto: `bundle exec rspec` inteiro verde (~9 min, ~2260 exemplos).
  Rode **sem** `SKIP_COVERAGE=1` ao menos uma vez antes de fechar: é a
  configuração real da suíte, e o caminho do simplecov só é exercitado assim.
- **Verde numa ordem não é verde.** A ordem dos exemplos é sorteada. Ao
  investigar vermelho, anote a seed que o RSpec imprime — sem ela a falha é
  irreproduzível — e use `rspec --seed <n> --bisect`, que isola o exemplo
  culpado sozinho. O CI registra a seed no resumo do job.
- **`before(:all)` vaza — limpe no `after(:all)`.** Só o exemplo roda em
  transação; o que o `before(:all)` cria é commitado e atravessa a fronteira
  entre grupos, inclusive o que as factories criam por associação. A suíte avisa
  no fim o que sobrou, `LEAK_AUDIT=1` aponta de qual grupo veio, e
  `LEAK_CHECK=strict` transforma o aviso em falha. Dívida conhecida em #643.
- **Envolver o contexto em transação parece o conserto e não é.** Passa inteira
  em SQLite e quebra sete exemplos em MariaDB: `Query#run_read_only_query` abre
  cliente próprio e a rake task de notificações é outro processo — nenhum dos
  dois enxerga dado não commitado.
- **Não commite por conta própria.** Deixe a mudança pronta na árvore de
  trabalho, mostre o diff e o resultado da suíte, e espere o mantenedor revisar.
  Commit, tag e push são dele — inclusive nos passos de baby-step, onde é fácil
  achar que "um commit por gem" autoriza commitar sozinho. Vale também para
  ramo novo: crie só quando pedirem.
- Documentação e comentário falam em **"mantenedor"**, não em nome próprio —
  o papel sobrevive a quem o exerce.
- **Antes de abrir issue, pesquise as existentes — inclusive as fechadas:**
  `gh issue list --state all --search "<termo>"`, variando termos em português e
  inglês. Achando issue relacionada, leia também os commits que a fecharam
  (`git log --all --grep="<numero>"`). Não é só evitar duplicata: é ali que está o
  contexto que torna a issue nova útil — decisão de produto já tomada, tentativa
  revertida, correção que só alcançou parte do código.
- **Não afirme impacto em produção sem verificar com o mantenedor.** O repositório
  não diz quais funcionalidades estão em uso. Issue é pública e irreversível;
  descreva o que foi medido no código e pergunte o resto.
- Convenção de trabalho vale para qualquer agente e vive **aqui**, versionada. A
  memória local do Claude Code não acompanha troca de máquina — guarde nela só o
  que for específico de uma sessão ou do ambiente.
- **Quando um comando falhar por bloqueio de sandbox, tente novamente fora do
  sandbox.** Isso dispara a pergunta de permissão; o usuário decide se executa.

## Skills do repositório

Em `.claude/skills/`. O Claude Code as descobre sozinho; a lista existe para
humanos e para outros agentes.

- `safe-refactor` — mede a mudança pela suíte local: cobre a lacuna, roda antes,
  muda, roda depois, compara. Primeiro recurso em refatoração, correção de bug,
  feature ou upgrade de dependência.
- `dependencias` — critério para declarar gem no `Gemfile` (restrição cobre
  exatamente o motivo, e o motivo fica escrito) e para conduzir campanha de
  atualização. Use antes de mexer em restrição de versão ou planejar um salto.
- `suite-mariadb` — sobe um MariaDB local fiel ao de produção e roda a suíte
  contra ele em vez do SQLite. Use ao mexer em SQL, unicidade, ordenação ou
  migration.
- `homologacao` — quando nem isso alcança: compara o SAPOS antes e depois em
  homologação, capturando telas, PDFs e planilhas nas duas versões, contra o
  mesmo banco.
- `release` — fecha o ciclo: merge fast-forward na `main`, tag anotada, label e
  issues no GitHub, release publicada. O deploy em si continua sendo do mantenedor.

## Atualização de dependências

- Uma gem por passo: `bundle update --conservative <gem>`, suíte completa,
  commit individual. Se quebrar, o commit aponta a gem exata.
- Alvo é o patch mais atual da mesma série minor/major. Nunca subir major ou
  minor de carona — isso é decisão separada.
- **Confira a versão resolvida no `Gemfile.lock`; não confie no `~>`.** Num
  update de segurança, `"~> 7.2.0"` resolveu para 7.2.3 em vez de 7.2.3.1 — a
  versão sem a correção — e a suíte verde não acusaria nada. Quando a intenção
  é piso de segurança, declare-o: `gem "rails", "~> 7.2.3", ">= 7.2.3.1"`.
- Gem transitiva não entra no `Gemfile` só para travar série. Use
  `bundle update <gem> --patch`, que restringe o bump sem tocar no arquivo.
- Higiene em lote (muitas gems atrasadas em patch) é exceção à regra de um passo
  por gem: `bundle update --patch --strict`, suíte, e bissecção **só se quebrar**.
  O `--strict` importa — sem ele o nível de patch é apenas preferência e o
  bundler pode subir além.

## Pontos cegos da suíte

A suíte roda em SQLite; produção é MariaDB com collation `utf8mb4_unicode_ci`
(case-insensitive **e** accent-insensitive) e `STRICT_TRANS_TABLES`. Isso muda
unicidade, ordenação e `LIKE` — num sistema em português, com acento em toda
parte, a diferença é real. Código que os testes nunca executam:

- `Query.run_read_only_query` (`app/models/query.rb`) ramifica por adaptador; o
  bloco `Mysql2` abre um cliente próprio e usa a configuração
  `<env>_read_only`. Protegido por specs com stub em `spec/models/query_spec.rb`.
- `config/initializers/recordselect_patch.rb` reabre `AbstractMysqlAdapter`.
- `db/seeds/02.reports_notifications.rb` tem um bloco atrás de `unless is_sqlite`
  que só carrega em MySQL.

Ao mexer nesses pontos, valide em homologação — verde local não basta.

## Monkey-patches

`config/initializers/` contém correções que dependem de interno do Rails e do
active_scaffold: `fix_rails7_date_format.rb`, `fix_url_for.rb`,
`recordselect_patch.rb`, `fix_rails61_active_scaffold_dependent_error.rb` e
`active_scaffold_disable_null_comparators.rb`. São os primeiros suspeitos em
qualquer upgrade de Rails.

## Dados sensíveis

O banco de homologação é réplica de produção, com dado real de aluno. Nunca
transcreva nome, e-mail, CPF ou nota para arquivos de trabalho, documentação ou
comentários de issue e PR — comentário de issue é público e irreversível.
Descreva achados genericamente: "aluno com nome acentuado", "registro id NNNN".
