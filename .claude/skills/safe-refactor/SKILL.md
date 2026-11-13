---
name: safe-refactor
description: Mede o efeito de uma mudança localmente, comparando a suíte antes e depois. Use ao refatorar, atualizar dependência, corrigir bug ou implementar feature — sempre que for preciso separar "o que eu mudei" de "o que já estava assim".
---

# Refatoração segura (local)

Mede a mudança em vez de confiar nela: roda a suíte **antes**, faz a alteração,
roda **depois** e compara. É o mesmo raciocínio da skill `homologacao`, mas com
a suíte local no lugar do ambiente real — mais barato e mais rápido, e por isso
o primeiro recurso. Escale para `homologacao` quando a suíte não alcançar o que
mudou.

## Passos

### 1. Se a mudança vem de fora, comece pelo changelog

Em upgrade de gem ou de framework, **o changelog é o que define onde olhar** —
não o contrário. Sem ele você mapeia o que imagina; com ele, mapeia o que mudou.
Por isso ele vem antes de tudo: antes de mapear o código, antes de escrever
teste, antes de tocar em qualquer linha.

(Numa refatoração ou feature, não há changelog: comece direto no passo 2.)

Leia no nível certo: **guia de upgrade e notas de versão**, não o CHANGELOG
completo de cada gem. O que interessa são as mudanças de comportamento e as
remoções, não as features novas e opcionais.

**Procure primeiro a página de migração da lib, e só caia no changelog se ela não
existir.** Projeto grande mantém uma, versionada e escrita para quem está subindo:
o Rails tem o *Upgrading Ruby on Rails* nos guides, mais as notas de versão de
cada série; outras libs guardam a mesma coisa num `UPGRADING.md`/`MIGRATION.md` no
repositório, numa seção "Upgrade" do README ou no corpo da release do GitHub. Vale
a busca explícita antes de abrir o changelog: essa página traz o **o que fazer**
ao lado da mudança, que o changelog apenas menciona.

Duas cautelas ao usar o guia:

- **É cumulativo.** Pular versões obriga a ler também os guias das intermediárias;
  o da série de destino pressupõe que as anteriores foram aplicadas.
- **Ele fala do framework, não deste projeto.** O que ele lista como "faça isto"
  ainda passa pela busca dirigida abaixo: boa parte não se aplica, e é justamente
  isso que encurta o trabalho.

Para cada item, faça uma busca dirigida no código. A maioria não vai se aplicar,
e isso é resultado: encurta a lista do que precisa ser testado à mão.

**O changelog diz a intenção; o diff diz o que mudou.** Quando um item parecer
tocar o projeto, leia o diff da própria dependência antes de concluir —
`gh api repos/<owner>/<repo>/compare/<tag antiga>...<tag nova>` devolve commits e
patch. O nome das tags sai de `gh api --paginate repos/<owner>/<repo>/tags --jq
'.[].name'` — `--paginate` porque a primeira página traz só as mais novas, e a
série que o `Gemfile.lock` fixa pode estar bem atrás —, e nem toda gem as prefixa
com `v`. Entrada que anuncia "adicionamos X" pode ser lógica que apenas **mudou de lugar**,
sem efeito nenhum na tela; o texto sozinho não distingue as duas coisas. Quando o
`gh api` não serve — gem fora do GitHub, tag que não bate com a versão publicada,
rede filtrada —, resta comparar o fonte instalado das duas versões
(`~/.rvm/gems/*/gems/<gem>-<versão>*/`; gem nativa leva sufixo de plataforma no
nome do diretório). É menos que o diff do repositório: a árvore instalada traz só
o que o gemspec empacota — sem `spec/`, muitas vezes sem changelog, nunca com
mensagem de commit —, e a versão antiga só está lá enquanto ninguém a removeu.

**Duas armadilhas nesse passo:**

- **Busca vazia não é evidência.** Se procurar um padrão e não achar nada,
  confirme que o padrão existe em algum lugar do projeto. Procurar `return`
  dentro de `transaction` e não achar nada só significa alguma coisa depois de
  saber que o projeto usa `transaction`.
- **Execute em vez de deduzir.** Ler o código sugere se um caminho é alcançável;
  rodá-lo prova. Um `rails runner` de três linhas resolve em segundos o que a
  leitura deixa em "provavelmente não".

Cada risco que sobreviver a essas duas checagens vira **teste**, não anotação.

### 2. Mapeie o alcance no código

O que esse código toca, e **o que dele os testes não executam?** Procure ramos
por ambiente ou adaptador, código só de produção, `rescue` silencioso, geração de
binário. Cobertura alta não significa que o caminho que você vai mexer é
exercitado.

### 3. Cubra as lacunas *antes* de mudar

Escreva os testes que faltam **contra o comportamento atual**, e confirme que
passam no código velho. Essa ordem é o que os torna rede de segurança; escritos
depois, eles apenas descrevem o que você acabou de fazer.

Quando o caminho é inalcançável no ambiente de teste (por exemplo, código que só
roda sob outro banco), ainda vale um teste com dublê fixando as APIs de que ele
depende — não prova o comportamento, mas pega deriva de assinatura.

### 4. Verifique que o teste não é vazio

Quebre o código de propósito, confirme que o teste falha **no exemplo esperado e
pela mensagem esperada**, e desfaça. Vale para o teste que você acabou de
escrever e para o que você supõe já cobrir a mudança. Teste que passa dos dois
jeitos não protege nada. Custa segundos.

Três maneiras de essa checagem mentir:

- **Simular a versão antiga de cabeça.** Num upgrade de gem, "como era antes" não
  se reconstrói de memória nem do changelog: **o código da versão anterior é a
  única simulação válida** — do diretório dela
  (`~/.rvm/gems/*/gems/<gem>-<versão>*/`) enquanto ainda estiver instalada, ou do
  fonte publicado. Substituir o método novo por uma aproximação escrita à mão
  produz uma versão que nunca existiu — e o vermelho que ela dá "confirma" um
  comportamento antigo imaginário.
- **Sabotagem não representativa.** Estragar um trecho de que o exemplo não
  depende não prova nada. Se o dado escolhido não atravessa o caminho alterado —
  uma consulta *sem parâmetro* para testar o repasse de parâmetros —, o arquivo
  é gerado e o teste passa mesmo com a sabotagem no lugar. Monte o dado de modo
  que só o percurso completo produza o resultado esperado: um valor distintivo
  digitado na entrada e conferido na saída.
- **Vermelho pelo motivo errado.** Contagem de falhas não basta, leia a
  mensagem. Timeout do Capybara, erro de carga e página que não abre aparecem
  como vermelho e passam por sabotagem bem-sucedida — e aí você conclui que o
  teste protege algo que ele nem enxerga.

### 5. Baseline

Rode a suíte inteira no código **sem a mudança** e anote os três números da última
linha do RSpec — `N examples, M failures, K pending` — e a duração.

Anote também a seed. A ordem dos exemplos é sorteada a cada run, e a linha
`Randomized with seed N` diz qual saiu. Rode o "depois" com `--seed N`: sem ela,
um vermelho que só a ordem nova expõe não se distingue de um que a mudança causou.
Quando a mudança acrescenta ou move exemplos, a mesma seed já não garante a mesma
ordem; aí um vermelho novo pede o baseline de novo sob a seed nova — e o
`--bisect` do `AGENTS.md` — antes de ser cobrado da mudança.

Isso não é formalidade. Sem baseline, uma falha depois da mudança é ambígua —
pode já estar quebrada. E se o baseline vier vermelho, **conserte o ambiente
primeiro**: um chromedriver defasado em relação ao Chrome derruba os feature
specs sem que nada no código esteja errado.

### 6. Mude em passos pequenos

Um passo, uma suíte, um commit. Se algo quebrar, o commit aponta a causa. Para
dependências, veja as regras em `AGENTS.md` — em especial a de conferir a versão
que de fato foi resolvida no `Gemfile.lock`.

### 7. Compare, e compare a contagem

Não olhe só "0 failures". **Compare os três números da última linha com os do
baseline, um a um** — exemplos, falhas e pending. Uma suíte verde com menos
exemplos significa que testes sumiram — arquivo que deixou de carregar,
`describe` que não roda mais, um `fit` esquecido (o `spec_helper.rb` liga
`filter_run_when_matching :focus`, então ele sozinho reduz a suíte ao que está
focado). Some com o mesmo efeito de uma regressão, e sem alarme.

**Pending não diminui a contagem**: o RSpec o conta em `N examples`. Spec que
virou `pending` ou `skip` mantém o total e só aparece como pending a mais — a
soma igual esconde. A lista `Pending:` no fim da saída diz qual é e por quê.

### 8. Interprete conforme a natureza da mudança

Aqui o critério muda, e é você quem decide:

- **Refatoração** — comportamento deveria ser idêntico, então *qualquer*
  diferença é defeito. Diferença nenhuma é o resultado esperado.
- **Correção de bug** — a diferença esperada é exatamente o comportamento
  corrigido. Qualquer outra é regressão.
- **Feature** — a diferença esperada é o comportamento novo, e o código antigo
  deveria seguir igual.

Nos três casos, **declare antes de rodar quais diferenças você espera** — na
refatoração a lista é vazia, e escrevê-la vazia já é a declaração.
Sem essa lista feita de antemão, é fácil olhar para uma diferença inesperada e
racionalizá-la como intencional.

## Rodar a suíte na prática

- **Núcleo antes das features.** Os *feature specs* (Capybara/Chrome) são a parte
  lenta e a única que trava. Rode primeiro o núcleo, que fecha em segundos e já
  exercita banco, modelos e requests:
  `rspec --exclude-pattern "spec/features/**/*_spec.rb"`. Só depois rode as
  features. Assim uma quebra no núcleo aparece na hora, sem esperar o Chrome.
- **Em background, não bufferize.** `... | tail -N` **esconde tudo até o fim** — o
  `tail` só imprime quando o pipe fecha, então o arquivo de saída fica vazio a run
  inteira e não dá para acompanhar nem ver onde travou. Rode sem o `tail`,
  deixando a saída fluir para o arquivo, e use `--format documentation`: é o
  formato que escreve uma linha por exemplo, com o nome, à medida que cada um
  termina. Com o `progress` o arquivo guarda pontos, e uma run travada não se
  localiza por eles. A última linha é o último exemplo que terminou: o travado
  veio logo depois, e os cabeçalhos de grupo acima dela dizem em que arquivo
  procurar.
- **Feature spec travado.** Se a run passa muito do tempo normal (~12 min) com um
  `chromedriver` girando, travou — mate e investigue, não espere. Confira Chrome ×
  chromedriver na mesma versão (o Chrome se auto-atualiza). Mas **versão casada não
  descarta o travamento**: página quebrada — asset que não compila, JS que mudou —
  faz o Capybara esperar para sempre por um elemento que nunca aparece. Aí a causa
  é a mudança, não o ambiente.

### Em paralelo (opcional)

O serial continua sendo o critério de pronto; o paralelo serve para iterar.

Cada worker tem banco próprio (`db/test.sqlite3`, `db/test2.sqlite3`): o
`database.yml` local precisa do `<%= ENV["TEST_ENV_NUMBER"] %>` no nome do banco
de teste, como no `.example`. Prepare-os uma vez, e de novo a cada troca de ramo
que mude o esquema — a armadilha do banco velho do `AGENTS.md` vale para todos:

    bundle exec rake "parallel:load_schema[2]"

Num checkout recém-clonado, rode antes um comando Rails serial
(`bundle exec rails runner ''`). Sem `SECRET_KEY_BASE` no ambiente, o primeiro
boot de teste grava o `tmp/local_secret.txt`, e N processos fazendo isso juntos
podem ler o arquivo ainda vazio: `secret_key_base ... got: ""`.

Rodada:

    PARALLEL_TESTS_EXECUTABLE='bundle exec rspec' SELENIUM_BROWSER=chrome \
      bundle exec parallel_rspec -n 2 --serialize-stdout --combine-stderr --verbose-rerun-command \
      -o '--seed N --format documentation --format ParallelTests::RSpec::RuntimeLogger --out tmp/parallel_runtime_rspec.log' spec

- `PARALLEL_TESTS_EXECUTABLE`: o `parallel_tests` prefere o `bin/rspec`, que está
  versionado sem bit de execução, e morre com `EACCES`.
- `--format documentation` repetido: qualquer `--format` passado em `-o`
  substitui o do `.rspec`, e a saída perde a linha de contagem.
- O log de runtime é o que equilibra os workers: com ele em `tmp/`, a divisão
  passa a ser por tempo; sem ele, por tamanho de arquivo, que deixa um worker com
  o grosso das features e quase não ganha nada. A primeira rodada o grava.
- `-n 2`: um terceiro ou quarto worker não encurta a rodada e custa um navegador
  de memória cada. Os navegadores disputam a máquina, a soma do tempo dos
  arquivos cresce com cada worker, e o tempo de um mesmo arquivo de feature varia
  tanto entre rodadas que a divisão por runtime não consegue equilibrar mais que
  dois.
- Compare a linha agregada (`N examples, M failures, K pendings`) com o baseline
  serial, como no passo 7. A mesma seed **não** dá a mesma ordem do serial: cada
  worker sorteia sobre o seu subconjunto de arquivos. Para reproduzir um
  vermelho, rode em serial o comando que o `--verbose-rerun-command` imprime para
  o worker que falhou, com a mesma seed — e o `--bisect` sobre essa lista.
- Apague `coverage/` antes de comparar cobertura entre rodadas.

## Quando a suíte não basta

Escale para a skill `homologacao` quando a mudança tocar algo que os testes
locais estruturalmente não alcançam:

- Código que ramifica por adaptador de banco — a suíte roda em SQLite, produção
  é MariaDB, com collation *case-* e *accent-insensitive* e tipagem estrita.
- Geração de PDF e planilha.
- Renderização de tela, layout e pipeline de assets.
- Envio de e-mail.

Ver a seção "Pontos cegos da suíte" em `AGENTS.md`.
