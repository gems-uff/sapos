---
name: dependencias
description: Decide como declarar uma gem no Gemfile e como conduzir uma atualização de dependências — uma gem por passo, ou uma campanha que move a cauda em lote por nível e o núcleo gem a gem. Use ao adicionar gem, mexer em restrição de versão, avaliar se um pin ainda se justifica, ou planejar e conduzir uma campanha de atualização (pontos de uso, patch, minor, o experimento dos majors, correção de CVE).
---

# Dependências: declarar e atualizar

Duas perguntas diferentes, que se confundem com facilidade. **Como declarar** é
política de longo prazo e mora no `Gemfile`. **Como atualizar** é operação e mora
nas flags do `bundle update` — nunca no arquivo.

A política de baby-step (uma gem por passo, alvo é o patch mais atual da série,
conferir a versão resolvida no lock) está no `AGENTS.md` e não se repete aqui.

## Parte 1 — Como declarar no Gemfile

### O princípio

Vale a distinção **biblioteca versus aplicação**:

- Uma **gem** (tem `.gemspec`) declara restrições permissivas. Ela coexiste com o
  bundle de terceiros, e apertar demais quebra a resolução de quem depende dela.
- Uma **aplicação** (tem `Gemfile.lock` versionado — o caso do SAPOS) **não
  precisa de restrição alguma para ser reprodutível.** O lock já faz isso.

Daí a regra que decide quase todo caso:

> Numa aplicação, restrição no Gemfile não serve para reprodutibilidade — serve
> para expressar política. Sem política a declarar, a linha certa é só o nome.

Não é preferência de estilo. O gerador do próprio Rails
(`railties/lib/rails/generators/rails/app/templates/Gemfile.tt`) produz
`web-console`, `capybara`, `selenium-webdriver`, `brakeman`, `bootsnap` e
`tzinfo-data` **sem restrição nenhuma**. As únicas que aparecem no template estão
em linhas comentadas, como sugestão. A si mesmo o Rails se pina na série minor,
porque um minor do Rails é migração de verdade.

### `bundle install` não sobe versão

`bundle install` **nunca** sobe versão sozinho. Num checkout limpo ele reproduz o
lock exatamente. A declaração do `Gemfile` só é consultada quando alguém digita
`bundle update`. Portanto não existe "patch automático" a ser ligado ou desligado
— o que a restrição controla é o teto do que um `bundle update` futuro pode fazer,
e nada mais.

### As formas e o que cada uma diz

| forma | exemplo | significa |
|---|---|---|
| só o nome | `gem "prawn"` | sem política; quem manda é o lock |
| `~> x.y.z` | `rails "~> 7.2.3"` | série minor travada, patch livre |
| `~> x.y` | `devise "~> 5.0"` | major adotado; o próximo é decisão à parte |
| `>= x.y.z` | — | piso; **não se usa** (ver abaixo) |
| versão exata | — | congelamento; hoje sem uso no projeto |
| `git:` + `branch:` | `carrierwave-activerecord` | versão não vem do rubygems |

**Piso de segurança não se declara.** O argumento a favor era real — `~> 7.2.3`
*permite* o 7.2.3.1 mas não o *obriga*, e num update de segurança a resolução
pode escolher a versão sem a correção. Mas o piso envelhece calado: quando sai a
correção seguinte, ele continua abaixo dela e passa a afirmar uma cobertura que
não existe, e ninguém revisa piso. O mecanismo que não envelhece é o `bundle-audit` no CI, que
compara o lock com a base de advisories baixada na hora e acusa também o
rebaixamento silencioso do resolvedor. A CVE fica registrada onde ela mora: na
base de advisories e na mensagem do commit que subiu a gem, não numa restrição.

### O critério

> **A restrição cobre exatamente o motivo, e o motivo fica escrito ao lado.**

Os dois lados importam. **Restrição que ultrapassa o motivo bloqueia correção sem
querer:** quando o motivo escrito é "o próximo major muda X", a restrição que ele
justifica é `~> x.y` — travar na versão exata recusaria, calada, um patch de
segurança backportado para a série. Confira sempre se a forma declarada é a mais
frouxa que ainda cobre o motivo. E teto sem motivo escrito é o defeito simétrico:
quem revisa daqui a dois anos não sabe se pode subir.

Quando um teto for precaução legítima e não impedimento conhecido — major de gem
de autenticação, por exemplo, que costuma exigir migração de dados —, o certo é
**escrever a precaução no comentário**, não remover o teto.

### O que não fazer

- **Pinar por simetria.** As gems sem restrição não são desleixo; são a forma
  idiomática. Uniformizar as ~45 seria andar contra a convenção e criar 45
  restrições que envelhecem a cada patch sem dizer nada a quem lê.
- **Pinar gem transitiva para travar série.** Use `bundle update <gem> --patch`.
- **Pinar em vez de usar flag.** Política de atualização é do comando, não do arquivo.

### `require: false`

`config/application.rb` chama `Bundler.require(*Rails.groups)`, que faz
`require "<gem>"` para toda gem dos grupos ativos, no boot. `require: false` diz
"instale e ponha no load path, mas não carregue". Dois casos:

- **Ferramenta de linha de comando** que o processo do app nunca usa: `rubocop`,
  `bundler-audit`, `brakeman`, `sdoc`.
- **Carga manual em outro momento:** `bootsnap`, requerido em `config/boot.rb`
  antes do Rails subir — não dá para esperar o `Bundler.require`.

A variante `require: "outro/caminho"` (`recaptcha`, `dotenv-rails`) não desliga
nada: carrega um arquivo de nome diferente do da gem.

## Parte 2 — Como atualizar

### O passo

- Uma gem por passo: `bundle update --conservative <gem>`, suíte completa,
  commit individual. Se quebrar, o commit aponta a gem exata.
- Alvo é o patch mais atual da mesma série minor/major. Nunca subir major ou
  minor de carona — isso é decisão separada.
- **Confira a versão resolvida no `Gemfile.lock`; não confie no `~>`.** Num
  update de segurança, `"~> 7.2.0"` resolveu para 7.2.3 em vez de 7.2.3.1 — a
  versão sem a correção — e a suíte verde não acusaria nada. Quem acusa é o
  `bundle exec bundle-audit check --update`: rode-o depois do update, antes de
  dar o passo por concluído. O CI repete a checagem.
- Gem transitiva não entra no `Gemfile` só para travar série. Use
  `bundle update <gem> --patch`, que restringe o bump sem tocar no arquivo.
- A exceção à regra de um passo por gem é a campanha (abaixo): a cauda anda em
  lote por nível — `bundle update --patch --strict`, depois `--minor
  --strict` —, com bissecção **só se quebrar**; o núcleo continua uma gem por
  passo.

### `--strict` quer dizer duas coisas

Não é o mesmo flag nos dois comandos, e a confusão é cara:

| comando | sem `--strict` | com `--strict` |
|---|---|---|
| `bundle update --patch/--minor` | o nível é **preferência**; o resolvedor ultrapassa se o grafo pedir | teto **rígido** |
| `bundle outdated` **sem filtro de nível** | mostra o último publicado no rubygems | só o que o **Gemfile permite** |
| `bundle outdated --patch/--minor` | já resolve dentro do Gemfile | **sem efeito** — o filtro de nível já restringiu |

Em `bundle update`, **sempre `--strict`** — sem ele o `--patch` deixa passar minor
e o `--minor` deixa passar major, calados.

### Diagnóstico: algum pin está bloqueando alguma coisa?

Compare o `bundle outdated` **pelado** com a versão `--strict`:

```
bundle outdated            # o que existe no rubygems
bundle outdated --strict   # o que o Gemfile deixa entrar
```

A diferença entre as duas listas é exatamente o que os pins bloqueiam.

**Não use os filtros de nível para esse diagnóstico.** `--patch` e `--minor`
resolvem dentro das restrições do `Gemfile` por conta própria, então `--minor` e
`--minor --strict` devolvem a mesma lista *sempre* — e a coincidência não diz nada
sobre pins. Pior: numa gem travada na série minor, `bundle outdated <gem> --minor`
responde **"Bundle up to date!"** enquanto o comando pelado mostra os minors
publicados. O flag esconde exatamente o que o diagnóstico procura.

### Sondagem antes de campanha

Para saber se um salto coletivo é viável sem se comprometer com ele:

```
bundle update --minor --strict      # ou --patch --strict
bundle exec rspec
```

A árvore limpa é o undo: `git checkout Gemfile.lock && bundle install`. **Não crie
ramo para a sondagem** — ramo só quando algo for ficar, e aí valem issue e ramo
`issue_NNN` da convenção.

Vermelho é informação barata: aborta e pronto. Verde **não** é autorização para
entrar tudo junto: o que entra em lote e o que vai gem a gem é o regime da
campanha (abaixo), e o bloco de dev/test (rubocop, pry, simplecov: chato e
seguro) vai separado do de runtime.

### Campanha

Uma campanha põe o `Gemfile.lock` em dia de uma vez: antes de um trecho de
trabalho que deve partir de dependências atuais, ou quando o `bundle-audit` e
os alertas do Dependabot se acumulam. Uma issue (Task) a acompanha, cada
degrau é uma sessão que termina com um comentário de resultados nela, e os
degraus vão nesta ordem: os pontos de uso, os patches, os minors, os majors.

**O regime.** A regra do passo (`AGENTS.md`) vale para o núcleo; a cauda anda
em lote.

- **Núcleo:** a gem sobre a qual o código é construído — os pontos de uso dela
  se espalham por muitos arquivos, ou a suíte alcança poucos deles, ou os
  minors dela trazem migração documentada. Uma gem por passo, até o minor mais
  novo da série, lendo antes todos os changelogs entre a versão travada e o
  alvo, e o guia de atualização. O passo se divide no minor cujo changelog
  anuncia migração (API removida, configuração que muda, default novo do
  framework), e esse minor é um passo à parte, com issue própria. Num framework
  em que todo minor é migração, como o Rails e o active_scaffold, a regra dá um
  minor por vez.
- **Cauda:** todo o resto — gem transitiva que o código não nomeia, ferramenta
  de desenvolvimento e teste, plugin do rubocop. Um lote por nível, todos os
  patches e depois todos os minors, sempre com `--strict` (o teto rígido da
  tabela acima), o diff do `Gemfile.lock` lido entrada a entrada, e bissecção
  só se ficar vermelho.
- **Major** nunca entra em lote: os majors são primeiro um experimento
  (abaixo), e cada um que entra é um passo à parte.

Quais gems são núcleo se mede no primeiro degrau e fica escrito na issue da
campanha; não se supõe.

**1. Os pontos de uso.** Cobertura de linhas do SAPOS não diz nada sobre uma
gem; o que importa é se a suíte executa as linhas que a usam. Em Ruby não há
import por arquivo — o `Bundler.require` carrega toda gem no boot —, então o
ponto de uso é a linha que nomeia uma constante da gem (`Prawn::Document`,
`Axlsx::Package`) ou chama o DSL que ela injeta nos modelos e controllers.
`git grep -n -w '<Constante>' -- app lib config` dá os pontos, e o
`coverage/.resultset.json` que o simplecov escreve depois de `bundle exec
rspec` (sem `SKIP_COVERAGE`) diz quais linhas de cada arquivo rodaram. Ponto
que a suíte não alcança é onde um update quebra sem vermelho: ele diz qual
conferência da parte 4 o degrau deve, e onde escrever teste de caracterização
antes de mexer numa gem do núcleo. Gem transitiva não tem ponto de uso
próprio: no `Gemfile.lock`, as gems sob as quais ela aparece são as que a
trazem, e os pontos delas é que a verificam.

**2. O inventário por nível.** `bundle outdated` pelado lista o que existe; o
nível de cada salto se lê das duas versões, e o que o `Gemfile` não deixa
entrar é decisão, não lote (ver "Diagnóstico").

**3. O lote.** `bundle update --patch --strict` num degrau e `bundle update
--minor --strict` no seguinte. O commit lista cada gem que andou. Um diff do
lock com gem fora do nível (um minor no lote de patch) é lote vermelho: o
`--strict` faltou.

**4. Lote vermelho se bissecta** (delta debugging): a partir do lock da base
(`git checkout Gemfile.lock && bundle install`), refaça o lote com a primeira
metade dos nomes (`bundle update --patch --strict <gem> <gem> ...`); a metade
que continua vermelha se divide de novo, até sobrar uma gem. Ela sai do lote e
vira passo à parte, no regime do núcleo; o resto do lote entra.

**5. Cada degrau**, lote ou gem: a suíte inteira antes e depois
(`safe-refactor`; sem `SKIP_COVERAGE` ao menos uma vez), o `bundle-audit check
--update`, o `rake javascript:check` quando o JS muda, e as conferências da
parte 4 que os pontos de uso pedirem — o golden-master e a `homologacao`
quando anda gem que desenha documento ou página, a recompilação dos assets
quando anda gem de asset. Um commit por lote e um por gem do núcleo, cada
mensagem listando o que andou e o que foi lido e medido.

**6. Os majors: primeiro um experimento**, numa árvore descartável, nunca no
checkout (`git worktree add --detach <rascunho>/majors main`). Na árvore,
afrouxe a restrição do `Gemfile`, `bundle update <gem> --conservative`, e a
suíte; agrupe as falhas pela mensagem do erro. Quando uma mensagem cobre quase
tudo, ela é uma primeira camada que esconde o resto: conserte-a na árvore
descartável, rode de novo, e repita até sobrar o esperado ou um custo de
verdade (o método Mikado: o objetivo na árvore descartável, os pré-requisitos
anotados, de volta à base). Quando a série antiga avisa o que a nova remove
(as deprecações do Rails), a suíte na base com os avisos visíveis dá a
superfície da migração nos caminhos que ela executa. Nada do experimento entra
como está: ele termina num relatório na issue da campanha — por major, o que
quebrou, quanto custaria e o que vem antes. O major que sai verde e lido vira
passo à parte; o que pede migração vira issue própria, com os pré-requisitos
no corpo.

### `bundle audit` antes de teorizar

```
bundle exec bundle-audit check --update
```

Antes de argumentar que uma série "não recebe mais patch de segurança", meça. A
CVE conhecida costuma ser uma só, e a base diz exatamente qual versão a corrige.
A mesma checagem roda no job `test` do CI; se ela passa lá e aqui, o lock está
limpo, sem depender de ninguém lembrar de subir um piso.

## Parte 3 — A dependência JS não passa pelo Bundler

Há uma só (`codemirror`, no `package.json`) e ela é servida de um jeito que não
se parece com gem nenhuma: o `node_modules` é **versionado**. O
`config/initializers/assets.rb` põe a pasta no asset load path do Sprockets, e é
de lá que o `application.js` carrega o editor. Nada ali é gerado por nós — é o
tarball publicado, descompactado. Por isso nenhum guia de instalação pede node
ou yarn: quem instala faz `bundle install` e `assets:precompile`, e a pasta
commitada é o que sustenta isso.

Atualizar é `yarn install` e commitar **tudo** o que mudar em `node_modules/`,
inclusive o `.yarn-integrity`. Só quem atualiza precisa de node.

```
bundle exec rake javascript:check
```

Confere se a pasta versionada ainda casa com o `package.json` e o `yarn.lock`, e
falha nos dois sentidos: lock à frente da pasta (alguém subiu a versão e não
rodou o `yarn install`) e pasta à frente do lock. Não precisa de node, de rede
nem de banco — lê quatro arquivos que já vêm no `git clone`. Roda no job
`checks` do CI, que é onde o erro precisa aparecer, porque ele se comete num PR.

Ela pega divergência de **versão**, não de conteúdo: arquivo editado à mão
dentro de `node_modules/codemirror` passa batido.

**Não ponha `/node_modules/` no `.gitignore`.** Já esteve lá e não fazia nada —
`.gitignore` só alcança arquivo não rastreado — enquanto sugeria a quem lia que
a pasta era descartável.

## Parte 4 — O que a suíte verde não prova

**Conteúdo de PDF e planilha está coberto** pelo golden-master de
`spec/requests/goldens/`, que compara o texto extraído do PDF e a matriz de
células do XLSX com baselines versionados em `spec/goldens/`. Toda view
`.pdf.prawn` e `.xlsx.axlsx` tem baseline ou, no caso da declaração, um feature
spec que lê o texto do PDF. Um upgrade de `prawn`, `prawn-table`, `caxlsx`,
`rubyzip` ou `pdf-reader` que mude o que o documento **diz** quebra a suíte.
Mudança intencional se aceita com `GOLDEN=overwrite`, conferindo o diff dos
baselines antes.

O que continua fora do alcance da suíte:

- **Layout.** Largura de coluna, quebra de página que não reordena texto,
  métrica de fonte e aparência do CSS. Só a skill `homologacao` enxerga isso.
- **Build local de assets.** Um `public/assets` existente sombreia a compilação
  viva, e `spec/support/asset_freshness.rb` recompila quando fonte **ou
  `Gemfile.lock`** ficam mais novos que o manifesto. Ao subir `sprockets`,
  `dartsass-sprockets` ou `sass-embedded`, confira que a mensagem `[assets] ...
  recompilando` apareceu no início da suíte; sem ela, o CSS testado é o da versão
  anterior.
- **Transitivas sem caminho de código.** `image_processing` e `ssrf_filter` vêm
  com o `carrierwave`, mas nenhum uploader processa imagem nem baixa por URL
  remota. Subir essas duas não exercita nada; não há o que testar.

E há uma dependência sem número de versão para raciocinar:
`carrierwave-activerecord` vem de um ramo de um fork do gems-uff (o nome do ramo
está no `Gemfile`). O lock fixa um SHA, então o dia a dia é estável, mas
`bundle update` nessa gem busca o *head* do ramo — seja lá o que estiver lá.
