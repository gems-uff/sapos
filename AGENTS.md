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
- **O assunto do commit começa por `Issue #NNN: `**, com o número da issue do
  ramo. O GitHub transforma o número em link, e o assunto é o que aparece na
  lista de commits e no `git log --oneline`. Depois do prefixo sobram cerca de
  60 colunas: imperativo, sem ponto final, e o porquê no corpo. Commit que não
  pertence a issue nenhuma — convenção, skill, infraestrutura — vai sem prefixo.
- **Cite a issue só pelo prefixo, sem `Fixes` nem `Closes`.** Essas palavras
  fecham a issue assim que o commit chega na `main`, e fechar é decisão do passo
  de release, separada de rotular: issue entregue pela metade leva o label e
  continua aberta (ver a skill `release`).
- **Exceção:** vulnerabilidade não ganha issue pública — enumerar o problema
  expõe o ataque antes da correção. Ramo direto da `main`, descrição genérica.
- Critério de pronto: `bundle exec rspec` inteiro verde (~9 min, ~2260 exemplos).
  Rode **sem** `SKIP_COVERAGE=1` ao menos uma vez antes de fechar: é a
  configuração real da suíte, e o caminho do simplecov só é exercitado assim.
- **Verde numa ordem não é verde.** A ordem dos exemplos é sorteada. Ao
  investigar vermelho, anote a seed que o RSpec imprime — sem ela a falha é
  irreproduzível — e use `rspec --seed <n> --bisect`, que isola o exemplo
  culpado sozinho. O CI registra a seed no resumo do job.
- **Prefira `before(:each)`: o rollback da transação limpa sozinho.** O
  `before(:all)` existe só para amortizar montagem cara entre muitos exemplos, e
  o ganho depende do tamanho do grupo — medido: em grupo de 6 exemplos não muda
  nada (0,78 s contra 0,79 s), em grupo de 69 corta pela metade (1,16 s contra
  2,36 s). Em grupo pequeno ele só traz fragilidade.
- **O que o `before(:all)` cria é commitado** e atravessaria a fronteira entre
  grupos, inclusive o que as factories criam por associação. Uma varredura ao fim
  de cada arquivo apaga o que sobrou, então **não escreva limpeza manual em
  `after(:all)`** — foi ela que errou em 90 arquivos (#643). A suíte avisa no fim
  se algo escapar, `LEAK_AUDIT=1` diz de qual grupo veio, `LEAK_CHECK=strict`
  transforma o aviso em falha.
- **Envolver o contexto em transação parece o conserto e não é.** Passa inteira
  em SQLite e quebra sete exemplos em MariaDB: `Query#run_read_only_query` abre
  cliente próprio e a rake task de notificações é outro processo — nenhum dos
  dois enxerga dado não commitado. Por isso a varredura vem **depois** do grupo,
  não em transação em volta dele.
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
- **Tudo que é acessível pelo usuário conta como em uso.** Não condicione
  validação a "se essa tela for usada": não há tela dispensável, e a pergunta só
  serve para encolher o escopo do que se vai verificar.
- **Antes de guardar um fato, pergunte: outro agente, noutra máquina, com só o
  `git clone`, conseguiria?** Se sim, é convenção e vive versionada — **aqui**, ou
  na skill a que pertence. A memória local do Claude Code não atravessa máquina:
  guarde nela só o que morre com ela — caminho local, comportamento do sandbox,
  estado de uma sessão. Id de registro sintético em homologação, por exemplo, é
  versionado (`routes_aluno.txt`), não memória.
- **Não duplique na memória o que já está versionado.** As duas cópias divergem
  na primeira mudança, e a que engana é justamente a que ninguém revisa. Se o
  fato já está no repositório, a memória certa é nenhuma.
- **Quando um comando falhar por bloqueio de sandbox, tente novamente fora do
  sandbox.** Isso dispara a pergunta de permissão; o usuário decide se executa.

## Skills do repositório

Em `.claude/skills/`. O Claude Code as descobre sozinho; a lista existe para
humanos e para outros agentes.

- `revisar-pr` — a espinha do ciclo de um PR: ler a issue e o diff, decidir o que
  é nosso e o que volta para o autor, cobrir o que falta, medir, homologar e
  lançar. Aponta para as demais; comece por ela ao pegar um PR ou retomar um ramo.
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
- `merge-downstream` — traz a `main` para dentro de um ramo de issue e confere se
  ela entrou inteira, inclusive o que o git não vê. Use ao atualizar ramo
  atrasado, ao revisar merge alheio, ou antes de aceitar um ramo para release.
- `release` — fecha o ciclo: merge fast-forward na `main`, tag anotada, label e
  issues no GitHub, release publicada. O deploy em si continua sendo do mantenedor.

### Skill é procedimento, não diário de bordo

Ao anotar aprendizado numa skill, o teste é: **uma rodada futura faria algo
diferente por causa desta linha?** Passa o mecanismo e a consequência ("a rota X
responde 500 no papel Aluno, ignore"; "`--flatten` é obrigatório, senão a bbox vem
vazia"). Não passa *quando* foi medido, em que versão, qual issue descobriu, nem
que o problema já foi corrigido — isso o `git log` já guarda, e na skill só
cresce.

Esse contexto tem para onde ir: **comentário na issue**. Medida de antes e
depois, versão em que o defeito aparecia, caminho que a rodada usou para
reproduzir, armadilha que custou tempo — tudo isso é útil, e ali fica junto do
trabalho que o originou, ao alcance de quem for reabrir o assunto.

Duas consequências práticas:

- **Não empilhe rodadas.** Anotação nova sobre o mesmo assunto **substitui** a
  antiga; não vira parágrafo "já corrigido, não procure mais". Lista de ruído
  conhecido é revisada na rodada em que se usa, e entrada que sumiu sai no mesmo
  commit.
- **Exemplo com número de versão apodrece.** Já aconteceu: as restrições citadas
  aqui como reais divergiram do `Gemfile` e passaram a enganar quem lia. Prefira
  a forma genérica; quando o concreto for necessário, cite o arquivo em vez de
  copiar o valor.

Script reusável é conteúdo legítimo de skill, e mora **na pasta da skill** — nunca
referenciado por caminho de uma captura datada, que é descartável.

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
- `db/seeds/02.reports_notifications.rb` tem um bloco atrás de `unless is_sqlite`
  que só carrega em MySQL.

Ao mexer nesses pontos, valide em homologação — verde local não basta.

## Monkey-patches

`config/initializers/` contém correções que dependem de interno do Rails e do
active_scaffold: `fix_url_for.rb`,
`fix_rails61_active_scaffold_dependent_error.rb` e
`active_scaffold_disable_null_comparators.rb`. São os primeiros suspeitos em
qualquer upgrade de Rails.

## Dados sensíveis

O banco de homologação é réplica de produção, com dado real de aluno. Nunca
transcreva nome, e-mail, CPF ou nota para arquivos de trabalho, documentação ou
comentários de issue e PR — comentário de issue é público e irreversível.
Descreva achados genericamente: "aluno com nome acentuado", "registro id NNNN".
