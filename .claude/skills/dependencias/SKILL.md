---
name: dependencias
description: Decide como declarar uma gem no Gemfile e como conduzir uma atualização de dependências. Use ao adicionar gem, mexer em restrição de versão, avaliar se um pin ainda se justifica, ou planejar uma campanha de atualização (patch, minor, piso de segurança).
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

### Um erro de leitura que já aconteceu aqui

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
| `~> x.y` + `>= x.y.z` | `devise "~> 5.0", ">= 5.0.4"` | major adotado; piso registrado |
| `>= x` sem teto | `nokogiri ">= 1.18.9"` | piso de segurança, teto nenhum |
| versão exata | — | congelamento; hoje sem uso no projeto |
| `git:` + `branch:` | `carrierwave-activerecord` | versão não vem do rubygems |

O par `~>` + `>=` faz **dois trabalhos distintos**: o til é teto ("não me
surpreenda"), o `>=` é piso ("nunca abaixo da versão corrigida"). O piso explícito
não é redundante — `~> 7.2.3` *permite* o 7.2.3.1 mas não o *obriga*, e num update
de segurança a resolução já escolheu a versão sem a correção. Quando a intenção é
piso de segurança, declare-o.

### O critério

> **A restrição cobre exatamente o motivo, e o motivo fica escrito ao lado.**

Os dois lados importam. Restrição que ultrapassa o motivo bloqueia correção sem
querer: `jquery-ui-rails` esteve travada em `"7.0.0"` quando o motivo documentado
justificava apenas `< 8.0.0` — a série 7.0 não tem patch hoje, mas se vier um, o
caminho provável é o backport da CVE, e a trava exata o recusaria calada. Virou
`~> 7.0.0`. E teto sem motivo escrito é o defeito simétrico: quem revisa daqui a
dois anos não sabe se pode subir.

Quando um teto for precaução legítima e não impedimento conhecido — major de gem
de autenticação, por exemplo, que costuma exigir migração de dados —, o certo é
**escrever a precaução no comentário**, não remover o teto.

### O que não fazer

- **Pinar por simetria.** As gems sem restrição não são desleixo; são a forma
  idiomática. Uniformizar as ~45 seria andar contra a convenção, criar 45 pisos
  que envelhecem a cada patch, e diluir o sinal dos `>=` que realmente escondem CVE.
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
sobre pins. Medido aqui: com `active_scaffold` travado em `~> 4.0.13` e o 4.3.1
publicado, `bundle outdated active_scaffold --minor` responde "Bundle up to date!",
enquanto o comando pelado mostra o 4.3.1. Três minors escondidos por um flag.

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
entrar tudo junto — separe o bloco de dev/test (rubocop, pry, simplecov: chato e
seguro) do bloco de runtime, e volte ao baby-step para o segundo.

### `bundle audit` antes de teorizar

```
bundle exec bundle-audit check --update
```

Antes de argumentar que uma série "não recebe mais patch de segurança", meça. A
CVE conhecida costuma ser uma só, e já documentada no `Gemfile`.

## Parte 3 — O que a suíte verde não prova

Medido neste projeto: os feature specs de PDF e planilha **conferem apenas o nome
do arquivo baixado**.

```ruby
expect(download).to match(/Histórico Escolar - Ana\.pdf/)
expect(download).to match(/Resumo Semestral - Defesa\(2022-2\)\.xlsx/)
```

São 13 views `.pdf.prawn` e 1 `.xlsx.axlsx`, e nenhuma asserção toca o conteúdo.
`prawn`, `prawn-rails`, `prawn-table` e `caxlsx` podem mudar largura de coluna,
quebra de página e métrica de fonte com a suíte inteira verde. O `liquid` está
melhor servido — `spec/lib/liquid_formatter_spec.rb` e
`spec/helpers/pdf_helper_spec.rb` cobrem a lógica no nível de unidade.

Ao mexer nessas gems, verde local não basta: use a skill `homologacao`. Cobrir a
lacuna de verdade exigiria extrair texto do binário (`pdf-reader`; comparar bytes
não funciona, o prawn embute timestamp e a ordem dos objetos varia) — trabalho com
valor próprio, e issue própria.

E há uma dependência sem número de versão para raciocinar:
`carrierwave-activerecord` vem de um ramo (`rails7`) de um fork do gems-uff. O lock
fixa um SHA, então o dia a dia é estável, mas `bundle update` nessa gem busca o
*head* do ramo — seja lá o que estiver lá.
