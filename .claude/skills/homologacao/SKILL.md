---
name: homologacao
description: Compara o SAPOS antes e depois de uma mudança em homologação, capturando telas, PDFs e planilhas nas duas versões e apontando o que divergiu. Use ao validar upgrade de dependência, atualização de framework ou refatoração ampla, quando a suíte verde não é evidência suficiente.
---

# Homologação comparativa (safe refactor)

Valida uma mudança rodando a aplicação **duas vezes contra o mesmo banco** — antes
e depois — e comparando o resultado. Serve para o que a suíte não cobre: MariaDB
real, dado real, Apache+Passenger, assets compilados, geração de PDF e planilha.

O valor está no controle: mesmo host, mesmos dados, só o código muda. Sem isso,
não há como separar diferença de código de diferença de ambiente.

## Pré-requisitos

- ImageMagick (`magick`) e `unzip`. O `compare_binary.rb` mede pelo composite do
  `magick`, não pelo binário `compare` — ver "Diferença esperada em PDF".
- `chromedriver` compatível com o Chrome instalado. Se os feature specs
  começarem a falhar no baseline, provavelmente o Chrome se atualizou e o
  chromedriver ficou para trás. Não adivinhe pela pasta do cache — pergunte ao
  Selenium Manager qual driver ele vai usar de verdade, que é quem decide:

  ```bash
  $(gem contents selenium-webdriver | grep 'bin/macos/selenium-manager') \
    --browser chrome --output json
  ```

  Ele usa o driver do `PATH` quando o major casa com o do Chrome, e só então
  recorre ao `~/.cache/selenium` (ou a um download). Um cache desatualizado não é,
  por si, problema.
- Um arquivo de credenciais **fora do repositório**, com `chmod 600`, contendo as
  três variáveis. Elas ficam juntas de propósito: amarrar a URL às credenciais
  evita apontar uma senha de homologação para outro ambiente.

```bash
# ~/.sapos_staging_env
export SAPOS_STAGING_URL=https://.../staging
export SAPOS_STAGING_USER=...
export SAPOS_STAGING_PASS='...'   # aspas SIMPLES: protegem espaço, $, ! e crase
```

Carregue com `set -a; source ~/.sapos_staging_env; set +a` antes de cada script.

## Ordem de execução

A ordem importa: escrita muda o que a captura enxerga, então cada lado escreve
**antes** de ser fotografado, nunca entre as duas fotos.

1. **Deploy da versão atual de produção** em homologação.
2. **Passada de escrita no lado "antes"** — ver "Passada de escrita". Os scripts
   se limpam sozinhos, então o lado volta ao estado em que começou.
3. **Captura "antes"** — os três conjuntos, em diretórios separados.
4. **Ações de escrita adicionais** que a rodada queira exercitar e que **não** se
   limpam (disparo de notificação, por exemplo), e **recaptura** dos conjuntos
   afetados, para que os dois lados reflitam o mesmo estado.
5. **Deploy da versão nova.**
6. **Passada de escrita no lado "depois"**, idêntica à do passo 2.
7. **Captura "depois"**, idêntica à do passo 3.
8. **Comparação** — as capturas e os JSON das duas passadas de escrita.

Entre 3 e 7 o banco **não pode ser reimportado**. Uma réplica nova traria
edições feitas em produção no meio do caminho, e diferenças de dado apareceriam
como se fossem de código.

Pelo mesmo motivo, as listas de rotas têm de ser as **mesmas** nos dois lados. Se
uma delas mudar no meio do ciclo — rota acrescentada, rota removida —, capture o
"depois" com a lista que produziu o "antes" (`git show <commit>:<arquivo>` para
um caminho fora do repositório) e só então adote a nova. Sem isso a comparação
acusa a rota que você mexeu, misturada com o que ela deveria medir.

### Onde as capturas ficam

Tudo mora em `~/capturas-sapos-staging/`, **fora do repositório** (contêm dado
real — ver "Regras de segurança"). Uma pasta por versão capturada, nomeada
`<data>_v<versão>_<rótulo>`, com `html/`, `extra/` e `bin/` dentro:

- `<data>` — dia da captura (`AAAA-MM-DD`), para ordenar cronologicamente.
- `<versão>` — a do cabeçalho, no alto à direita (`Versão 7.15.21-27-gc0e804a2`).
  Ela aparece **antes da autenticação**, então um `curl -sL "$SAPOS_STAGING_URL/users/sign_in"`
  já a devolve; não é preciso subir navegador só para conferir qual build está
  no ar. Ela identifica o
  código exato.
- `<rótulo>` — o que aquela versão é (`producao`, `rails72`, `security_updates`).

As pastas antigas ficam ali como arquivo das rodadas anteriores; não as apague ao
começar uma nova. Cada rodada compara duas dessas pastas — a "antes" e a "depois".

```bash
set -a; source ~/.sapos_staging_env; set +a
S=.claude/skills/homologacao
CAP=~/capturas-sapos-staging

# Ajuste as duas versões à rodada. Nomeie pela versão do cabeçalho de cada deploy.
ANTES=$CAP/<data>_v<versão>_<rótulo>
DEPOIS=$CAP/<data>_v<versão>_<rótulo>

bundle exec ruby $S/capture_html.rb   $ANTES/html   $S/routes_html.txt
bundle exec ruby $S/capture_html.rb   $ANTES/extra  $S/routes_extra.txt
bundle exec ruby $S/capture_binary.rb $ANTES/bin    $S/routes_binary.txt

# ... deploy da versão nova, e o mesmo com $DEPOIS/{html,extra,bin}

ruby $S/compare_html.rb   $ANTES/html  $DEPOIS/html
ruby $S/compare_html.rb   $ANTES/extra $DEPOIS/extra
ruby $S/compare_binary.rb $ANTES/bin   $DEPOIS/bin
```

## O que cada lista cobre

- `routes_html.txt` — índices do active_scaffold, relatórios e telas de apoio.
  Rotas GET sem parâmetro, geradas de `rails routes`.
- `routes_extra.txt` — telas de registro individual e as de **simulação**, que
  são o único ponto da varredura que executa `Query.run_read_only_query` pelo
  ramo `Mysql2`. Rodam com `skip_update: true`: não escrevem nem enviam e-mail.
- `routes_binary.txt` — PDFs e planilhas, que exercitam `prawn` e `caxlsx`.

Os ids são de registros existentes em homologação. Se o banco for reimportado,
confira-os antes de rodar.

### Capturando por papel

O `ability.rb` decide pelo papel **ativo** (`actual_role`), não pelo conjunto de
papéis da conta: ter `ROLE_ALUNO` não basta para abrir `/enrollment/:id`. O
`capture_html.rb` aceita `--role=<nome do combo>` e troca o papel pelo próprio
seletor do cabeçalho antes de capturar, conferindo depois que ele pegou.

```bash
bundle exec ruby $S/capture_html.rb $ANTES/aluno $S/routes_aluno.txt --role=Aluno
```

Cada papel vai para um diretório próprio, e a comparação é sempre papel contra o
mesmo papel. O combo só é renderizado para contas com **dois ou mais** papéis —
com um só, o script aborta dizendo isso, em vez de capturar as telas do papel
errado.

**Passe `--role` sempre, inclusive para o administrador.** O papel ativo é
gravado no usuário (`actual_role`) e **atravessa execuções**: uma captura sem
`--role` herda o que a anterior deixou e capturaria as telas administrativas como
aluno, sem erro nenhum. O script grava o papel usado em `papel.txt` dentro do
diretório de saída e avisa quando herdou — confira esse arquivo antes de comparar.

## Como a comparação é feita

- **Texto de página** — hash do texto visível, com a faixa de versão do cabeçalho
  neutralizada. Datas **não** são normalizadas de propósito: mudança de formato
  de data é uma das regressões procuradas.
- **Screenshot** — PNG de página inteira, comparado pixel a pixel, porque texto
  igual não é tela igual: asset que sumiu, CSS que quebrou e layout deslocado não
  mudam uma letra do texto visível. A saída **agrupa as páginas pela bounding box
  da diferença**, e é assim que se lê: a string de versão está em toda página, na
  mesma posição, então ela vira um grupo único com quase tudo dentro — e o que
  divergiu por outro motivo sobra em grupo próprio, no topo (a ordem é por área).
  Espere a varredura inteira colapsar em poucas linhas; leia as de cima.
  Nenhuma coordenada fica escrita no script: neutralizar a faixa da versão por
  coordenada fixa quebraria com outro tema, zoom ou resolução.
- **PDF** — rasterizado em PNG por página. Comparar bytes não funciona: PDF
  embute data de criação, então o mesmo relatório gerado duas vezes já tem hash
  diferente.
- **XLSX** — descompactado; o diff é no XML interno, ignorando `docProps/core.xml`.
- **Status HTTP, erros de console e requisições que falharam** — de onde vêm os
  sinais mais baratos. Quebra de upgrade costuma ser 500, e asset faltando
  aparece como 404 de rede.

## Verifique o instrumento, não só o sistema

Um comparador quebrado também devolve "nenhuma diferença", e é o mesmo resultado
que "nada regrediu". Três checagens separam os dois, e nenhuma é opcional:

- **Contagem sem normalizar.** O `compare_html.rb` imprime quantas páginas
  diferem **sem** neutralizar o cabeçalho. Como as duas versões têm strings de
  versão diferentes, esse número tem que ser alto. Zero ali, junto com zero no
  resultado principal, é comparador quebrado.
- **Contagem por pixel.** Vale o mesmo: com duas versões diferentes, zero página
  alterada por pixel é o comparador, não o sistema. O `compare_binary.rb` tem
  checagem de sanidade própria para isso.
- **Sessão perdida.** Uma rota que caiu na tela de login grava **200** e casa
  perfeitamente entre "antes" e "depois" — passa por "sem diferença" sem nunca
  ter sido vista. O `capture_html.rb` avisa (`SESSAO PERDIDA`) comparando a URL
  final; se o aviso aparecer, aquelas rotas não valem como evidência.

## Camada exploratória (interativa) — o que a varredura estática não alcança

A comparação acima é um **retrato estático**: carrega a rota, tira foto, lê o
texto. Ela **não clica, não digita, não dispara AJAX e não escreve**. Passa longe
de coisas que um upgrade quebra e que só aparecem interagindo:

- **Formulários de escrita** (active_scaffold `new`/`edit` + salvar) — persistência,
  formato de data ao salvar, sanitização de HTML (loofah/rails-html-sanitizer).
- **`recordselect` sobre MariaDB** — a busca AJAX por associação executa
  `recordselect_patch.rb` (reabre `AbstractMysqlAdapter`) e a collation
  accent-insensitive; a suíte roda SQLite e **nunca toca esse caminho**.
- **Widgets JS** — datepicker/timepicker jquery-ui (assets), que a foto estática
  não exercita.
- **E-mail / Devise** — reset, confirmação, notificações. Ver as travas em
  "Regras de segurança".

Faça uma passada exploratória sempre que o upgrade mexer em asset (jquery-ui),
sanitizador, Devise, active_scaffold ou o adaptador MySQL. É complementar, não
substitui a estática.

O `probe_widgets.rb` desta pasta já cobre o caso mais comum: estilo computado de
CodeMirror, tema das listas, `record_select` e datepicker — a mesma medida nos
dois lados, num JSON por rodada.

```bash
EXPLORE_OUT=$ANTES/exploratorio ROTULO=antes bundle exec ruby $S/probe_widgets.rb
```

Comparar é diferenciar os dois JSON. Para medir o que ele não mede, acrescente
seção **e recapture os dois lados**: sonda alterada no meio da rodada mede o
instrumento, não a aplicação.

### Estado que atravessa requisições

A varredura estática carrega cada rota do zero, então **nada nela mede sessão**:
filtro, ordenação e página que se perdem entre uma requisição e a seguinte
passam pelas rotas todas sem um pixel de diferença. O `probe_sessao.rb` cobre
isso na tela de Turmas — filtra, pagina, ordena e volta à lista, na mesma sessão.

```bash
EXPLORE_OUT=$LADO/sessao bundle exec ruby $S/probe_sessao.rb
```

Três coisas que essa medida ensina, e que valem para qualquer sonda de sessão:

- **É a TROCA de filtro que mede.** Sob um filtro só, a página 2 sai correta
  mesmo com a sessão quebrada, porque a busca guardada ainda é a certa. Uma
  sonda que filtra uma vez e pagina devolve verde sempre.
- **A primeira busca da sessão é privilegiada**, então a sonda abre sessão nova
  antes de medir. Sem isso, quem congela é a busca que a própria descoberta de
  dados fez, e as duas rodadas medem coisas diferentes.
- **Zero linhas não é veredito.** Lista vazia pode ser "o filtro não pegou" ou
  "o servidor está filtrando outra coisa". A sonda lê o `data-search` da faixa
  de filtro do active_scaffold — o ano que o **servidor** diz estar aplicando —
  e é esse campo, não a contagem, que se compara entre os dois lados.

O relatório traz, por passo, `ano_filtrado_pelo_servidor` e `filtro_correto`.
Comparar é diferenciar os dois JSON.

### Medir por leitura o que o formulário exige

Nem toda pergunta sobre formulário precisa de escrita. O que a página **exige de
quem preenche** está no HTML renderizado, e se lê sem submeter nada — o que torna
a medida repetível nos dois lados, em qualquer ordem, sem restaurar banco. É o
que o `probe_formulario.rb` faz sobre a candidatura.

```bash
EXPLORE_OUT=$ANTES/leitura bundle exec ruby $S/probe_formulario.rb        # descobre os registros
EXPLORE_OUT=$DEPOIS/leitura bundle exec ruby $S/probe_formulario.rb 859   # ids escolhidos
```

**No "depois", passe TODOS os ids que o "antes" mediu**, não só o exemplar
principal. Sem id a sonda redescobre os registros e mede um conjunto diferente;
o diff então acusa registro que existe de um lado só, e isso é o instrumento
falando, não a aplicação. Os ids medidos estão no JSON do "antes".

A medida central é a **divergência entre duas obrigatoriedades que se confundem**:
o `<li>` ganha a classe `required` quando a *configuração do template* pede o
campo; o atributo no input é o que o *navegador* exige. Campo que a configuração
pede e o navegador não exige passa da tela para o servidor e volta recusado. Ler
só o atributo não distingue isso de campo opcional.

Três coisas que essa leitura ensina, e valem para qualquer sonda de formulário:

- **Compare por grupo, não por input.** Campo composto — cidade/estado/país,
  rua/número — é um campo com três inputs e um `required` só, por desenho. Input
  a input, os outros dois aparecem como defeito. O grupo está coberto se
  **qualquer** input dele exigir.
- **Registro que não tem o caso não serve de exemplar.** Campo de arquivo que não
  é obrigatório na configuração não demonstra nada sobre `required` em campo de
  arquivo, por mais arquivo que tenha gravado. Escolher o registro é parte da
  medida, não preliminar dela.
- **Página que não montou o formulário devolve lista vazia**, e zero se lê como
  "nada exigido" em vez de "não medi". Recuse a medida e registre o que havia na
  página. Na réplica, a maioria das candidaturas cai nisso e a causa é uma só: o
  parcial devolve a string `Acesso inválido` quando o processo está com
  `staff_can_edit` desligado. É desenho — escolha outra candidatura.

**Nem toda exigência é o `required` do HTML5**, e a leitura sozinha não distingue.
Parte dos campos é barrada por função registrada em `customFormValidations`, que
o `apply/edit.html.erb` roda na submissão. Ler o atributo e concluir "ninguém
exige" acusa esses campos de um defeito que não têm. O que a leitura consegue
dizer é se *existe* validação própria no grupo — a fonte da função referencia os
elementos por id —, não o que ela verifica. Duas medidas para não refazer:

- **Radio confere presença**: quando o campo é obrigatório, o parcial registra
  validação que reprova se nada estiver marcado. Está coberto.
- **Arquivo não confere presença**: a validação dele checa tamanho e extensão, e
  retorna vazio quando não há arquivo. Campo de arquivo obrigatório sem `required`
  e sem arquivo gravado é lacuna de verdade, não campo coberto.

Campo de arquivo **com** arquivo gravado sem `required` é o esperado: o navegador
não pré-preenche input de arquivo, e marcar `required` ali trava a submissão
inteira em silêncio. A exigência fica no servidor.

### Submeter o formulário, que é o que a leitura não alcança

Ler prova o que a página **exige**; só submeter prova o que ela **faz**. O
`probe_submissao.rb` preenche o formulário público de candidatura inteiro,
deixa **um** campo em branco e tenta enviar — medindo se o navegador barra e em
qual campo.

```bash
bundle exec ruby $S/abrir_processo_seletivo.rb abrir 5
EXPLORE_OUT=$OUT bundle exec ruby $S/probe_submissao.rb              # só o bloqueio, não escreve
EXPLORE_OUT=$OUT bundle exec ruby $S/probe_submissao.rb --confirmar  # submete e apaga o que criou
bundle exec ruby $S/abrir_processo_seletivo.rb fechar 5
```

O modo padrão não cria nada e já serve de regressão barata: obrigatório que
deixou de ser exigido no cliente aparece como **não bloqueou**, ou como bloqueio
num campo diferente do esperado — por isso o relatório traz `barrou_no_alvo`, e
não só `bloqueou`.

**Não bloquear tem dois desfechos, e confundi-los esconde o defeito.** Navegador
que barra sequer posta: a URL continua em `/apply/new`. Se postou, ou o servidor
aceitou, ou recusou e re-renderizou — e aí a URL vira `/apply` **sem criar
registro**, o que passa fácil por "foi bloqueado". O relatório separa os três.

Três medidas que custam uma rodada cada:

- **A busca do active_scaffold é por campo: `?search[name]=`.** Um `?search=`
  solto não filtra nada e devolve a lista inteira, que se lê como "não achei".
- **A lista padrão de candidaturas vem filtrada.** Registro recém-criado pode
  não aparecer nela; procure pelo marcador `ZZ-TESTE-HOMOLOG`, não pela lista.
- **O campo de foto aceita só jpg.** Mandar pdf nele reprova na validação
  própria, com mensagem nomeando o campo — e o relatório acusa um bloqueio que é
  do instrumento, não do sistema.

**Antes de escrever sonda para uma correção que veio de fora, prove que o caminho
dela executa aqui.** Procure a chamada, a configuração que a liga, a condição que
a guarda — e confirme que o padrão existe em algum lugar do projeto, porque busca
vazia não é evidência. Sonda para caminho inalcançável devolve "sem diferença", e
isso se lê como "não regrediu": é pior do que não medir, porque consome a rodada e
entrega falsa garantia. Correção que não alcança este sistema entra no relatório
como tal, sem instrumento.

O `explore_common.rb` desta pasta é o ponto de partida para sonda nova: sobe o
Chrome headless, loga lendo as mesmas env vars da captura e dá helpers de
screenshot e de erro de console. Escreva os passos da rodada como scripts curtos
ao lado dele, apontando `EXPLORE_OUT` para o diretório da rodada — os
screenshots contêm dado real e não podem cair no repositório. A extensão do
Chrome pode estar indisponível; Selenium headless + screenshots avaliadas por
visão contorna isso.

Regras da passada: só `new`/`edit` **sem salvar** onde der; a única escrita
persistida é em tabela de apoio com rótulo `ZZ-TESTE-HOMOLOG`, apagada ao fim;
e-mail só com a trava `redirect_email` conferida.

**Chame `switch_role!` no início de toda sonda.** O papel ativo atravessa
execuções tanto aqui quanto na captura, e a captura do aluno costuma ser a
última — a sonda seguinte navega como aluno e não acha link de edição nenhum. O
sintoma mente: parece "a tela sumiu", não "papel errado".

**Chegue à tela como o usuário chega.** Navegar direto para a rota de uma ação do
active_scaffold monta a tela sem o link de ação que o JS dela procura, e o script
estoura sozinho (`find_action_link(...)` devolve `undefined`). O erro é da sonda e
some quando se clica a ação a partir da lista.

**Drene o log de console entre fluxos** (ler é que drena). Um fluxo que sai pelo
caminho de erro sem ler o console empurra os próprios erros para o relatório do
fluxo seguinte, que os reporta como se fossem da tela dele.

**Booleano do active_scaffold se lê no `checked`, nunca no campo oculto.** A
lista renderiza cada booleano como o par do Rails — um `input[type=hidden]` com
valor `0` mais um `input[type=checkbox]` —, então o oculto vale `0` em **toda**
linha, marcada ou não. Ler o oculto responde "nenhum registro tem a flag" para
qualquer coluna, e o falso negativo parece medida: leva a criar na réplica um
caso que ela já tinha. O `innerText` da célula também não serve — vem vazio nos
dois estados.

**Conte elementos dentro do container, não por padrão de nome.** Um seletor por
nome que não casa devolve sempre o mesmo número: a medida fica idêntica nos dois
lados e cega a qualquer regressão. Meça algo que **mude** quando você mexe na
tela, e confira que mudou, antes de confiar na comparação.

### Passada de escrita — obrigatória quando a rodada precede uma release

A comparação inteira é de leitura: ela prova que as telas continuam iguais, e não
prova que **salvar** continua funcionando. A skill `release` exige essa passada
antes de lançar; **faça-a como parte da rodada, sem esperar pedido.**

**Rode nos dois lados, como tudo o mais.** Um só lado responde "salvar funciona
agora?", que é portão de release; os dois respondem "a mudança quebrou o salvar?",
que é a pergunta desta skill. Sem o lado "antes", ciclo que falha é ambíguo — pode
já estar assim —, e é exatamente essa ambiguidade que a rodada existe para
eliminar.

Onde ela entra na ordem: **antes da captura de cada lado** (passos 2 e 6), e
nunca entre a captura "antes" e a "depois". Os dois
scripts se limpam sozinhos — foto que sobe e sai, candidatura que é criada e
apagada —, então cada lado volta ao estado em que começou e as capturas dos dois
lados enxergam a mesma coisa. O rastro que sobra é linha em `/versions` e
`/reports`, que já divergem sempre por causa da própria varredura.

```bash
# passo 0: confira redirect_email (ver "Regras de segurança"). Trava em "".
# LADO=$ANTES antes de capturar o antes; LADO=$DEPOIS antes de capturar o depois.
EXPLORE_OUT=$LADO/escrita bundle exec ruby $S/probe_escrita.rb              # diagnostico
EXPLORE_OUT=$LADO/escrita bundle exec ruby $S/probe_escrita.rb --confirmar  # ciclo de foto

bundle exec ruby $S/abrir_processo_seletivo.rb abrir 5
EXPLORE_OUT=$LADO/submissao_escrita bundle exec ruby $S/probe_submissao.rb --confirmar
bundle exec ruby $S/abrir_processo_seletivo.rb fechar 5

diff $ANTES/escrita/probe_escrita.json $DEPOIS/escrita/probe_escrita.json
```

Numa rodada em que o lado "antes" não foi corrido — porque a versão antiga já saiu
do ar, por exemplo —, a passada no lado novo ainda vale como portão de release.
Só não a leia como comparação: falha ali exige conferir a versão anterior antes de
culpar a mudança.

O que cada um cobre, e o que ler no relatório:

- `probe_escrita.rb --confirmar` — formulário administrativo com upload
  CarrierWave sobre o aluno de teste: sobe foto, salva, confere, remove, salva,
  confere. O veredito é `voltou_ao_estado_inicial: true`, com
  `upload_persistiu` e `remocao_persistiu` verdadeiros. Falso em qualquer um
  deles é caminho de escrita quebrado, não ruído.
- `probe_submissao.rb --confirmar` — formulário público de candidatura de ponta
  a ponta: `criou: true` na fase 2 e `restantes com o marcador: 0` na limpeza.
  **Resíduo na réplica é defeito da rodada**, não da aplicação: se sobrar
  registro com o marcador, apague antes de seguir.

O que a passada **não** cobre, e por isso não se conclui dela: disparo de e-mail.
Só exercite e-mail quando a mudança tocar Devise, `lib/notifier.rb`, template de
mensagem ou a entrega — e aí siga as "Regras de segurança", que pedem o valor
vivo de `redirect_email` antes de qualquer disparo. Upgrade que não toca nada
disso não justifica destravar a variável numa réplica de produção.

### Zero diferença na estática não é evidência sobre widget

Widget que só existe depois de um clique **não está na foto** — nenhuma rota da
varredura abre um calendário. Um datepicker pode trocar de tema por inteiro e
passar pelas rotas todas sem um único pixel de diferença.

Então, quando a mudança toca asset de widget (jquery-ui, datepicker, timepicker,
record_select, CodeMirror), a estática **não vota**: ela cobre status, texto e
layout de página, outra coisa. A regressão só aparece na camada exploratória,
medindo estilo computado do widget aberto.

E cuidado com a sonda que **força** o widget a existir — vincular o datepicker à
mão (`jQuery('._param_type_date').datepicker()`) contorna um bind automático que
falhou e mede o tema, mas **não** mede se o widget aparece para o usuário. São
duas regressões diferentes, e forçar o bind esconde a segunda. Quando precisar
forçar, registre o que ficou por medir em vez de deixar a homologação parecer
completa.

## Preparando o ambiente para o papel de aluno

**O banco de homologação é regerado por dump de produção de tempos em tempos.**
Todo dado inserido por uma rodada some nessas horas, e com ele as rotas do
`routes_aluno.txt`, que deixam de responder. Trate esse conjunto como algo a
**refazer**, não a preservar: rodar
`preparar_aluno_de_teste.rb --confirmar` recria o que faltar, deixa em paz o que
existe, e imprime as linhas prontas para o `routes_aluno.txt` — os ids mudam a
cada regeração. Rodar sem necessidade não custa nada.

O script cobre o conjunto inteiro, na ordem certa, e confere cada etapa. Os dois
primeiros passos já foram manuais, pela armadilha descrita adiante; deixaram de
ser quando a conta de captura passou a ser criada pelo script de migração da
réplica — é a existência dela que arma a trava, então o script agora exige a
conta e aborta sem ela, em vez de confiar em quem executa.

As telas do aluno precisam de três coisas que a réplica de produção não traz
prontas. **A ordem não é indiferente.**

1. **Criar o aluno**, com rótulo `ZZ-TESTE-HOMOLOG` no nome (é por ele que a
   limpeza varre depois) e **o e-mail da conta de captura**.
2. **Editar a conta de captura**: *acrescentar* o papel Aluno — nunca trocar, sem
   o de Administrador a própria captura perde acesso — e associá-la ao aluno.
3. **Só então criar a matrícula**, com Tipo de Matrícula que tenha "Com usuário"
   marcado (hoje é `Regular`); sem isso o `_valid_enrollment` nega o acesso do
   próprio aluno.

**Por que essa ordem e não outra:** o `after_create` da matrícula chama
`Enrollment#create_user!`, que faz `User.invite!` com o e-mail do aluno. Se esse
e-mail já pertence a alguém, o `invite!` levanta e o `rescue` faz
`User.where(email: ...).destroy_all` — **apagaria a conta de captura**. Com o
aluno já tendo usuário, `should_have_user?` → `can_have_new_user?` → `has_user?`
corta antes de chegar lá. E `has_user?` já é verdadeiro pela simples existência de
um usuário com aquele e-mail, o que torna o passo 1 a primeira trava.

O combo de troca de papel só aparece depois do passo 2 (ele exige dois papéis);
é ele que o `--role` do `capture_html.rb` usa.

### Se precisar do formulário público de inscrição

A réplica não tem processo seletivo aberto, e **todos os processos dela vêm com
`require_session` ligado** — que faz o `prepare_new_admission_application`
desviar antes de o pedido chegar ao controller. São dois campos a mexer, não só
a data. O `abrir_processo_seletivo.rb` abre, exercita e reverte os dois na mesma
execução, conferindo o que gravou.

Prefira exercitar o **create**: ele só precisa do processo aberto, enquanto o
update exigiria o token de uma inscrição de candidato real.

### Se não houver período de inscrição aberto

A tela `/enrollment/:id/enroll/:ano-:semestre` redireciona com "o período de
inscrições fechou" quando nenhuma janela está aberta, e `/enrollment/:id` aparece
sem a parte de inscrição. **Confira antes** em *Disciplinas → Quadros de
Horários* se o último quadro cobre a data de hoje; se cobrir, não crie nada.

Se não cobrir, `abrir_quadro_de_horarios.rb` cria um com as janelas abertas:

```bash
bundle exec ruby $S/abrir_quadro_de_horarios.rb 2026 2              # simulação
bundle exec ruby $S/abrir_quadro_de_horarios.rb 2026 2 --confirmar  # cria
```

Ele recusa duplicar quadro do mesmo ano/semestre, e escalona as janelas (a
principal fecha primeiro, depois a de inserção, depois a de remoção) para que a
captura consiga exercitar tanto a inscrição quanto o período de ajustes.
**Abrir período dá assunto à rake task de notificações** — confira o
`redirect_email` antes, na tabela verdade abaixo.

## Dirigindo a interface por Selenium

- **O `record_select` não filtra com `send_keys` de uma vez.** A requisição sai
  como `.../browse?search=` **vazia** e a lista volta sem filtro — e o primeiro
  item dela é outro registro, então clicar no primeiro associa o **errado**, em
  silêncio. Digite caractere a caractere (`each_char` com ~0,3 s) e espere o item
  aparecer antes de clicar. Vale para qualquer script Selenium sobre o SAPOS.
- **A busca do active_scaffold fica atrás do link "Buscar"**; só depois de clicar
  nele existe o campo (`input[name='search']`, id `as_<recurso>-search-input`).
- **`execute_script` derruba o chromedriver na tela de novo Quadro de Horários**
  (medido duas vezes seguidas). Nas telas com datepicker, prefira
  `find_element` e `page_source` a JS injetado.
- **Confirme pela lista, nunca pela ausência de erro na tela** — ver o 500 abaixo,
  que grava o registro e mostra "Internal Error" ao mesmo tempo.

## Ruído conhecido, que não é regressão

Estas rotas não respondem 200 na varredura, e não é defeito da aplicação:

- `406` em `/advisements/to_pdf`, `/enrollments/to_pdf`, `/scholarships/to_pdf`,
  `/scholarship_durations/to_pdf` e `/email_templates/builtin` — a lista chama a
  rota sem o formato que ela exige.
- `404` em `/cities/autocomplete`, `/countries/autocomplete`,
  `/states/autocomplete` e `/notifications/notify` — rotas que só existem com
  parâmetro.
- `500` (`CanCan::AccessDenied`) em `/pendencies`, **no papel Aluno**.

Aparecem nos dois lados da comparação e devem ser ignorados como achado — mas se
**mudarem** de status entre "antes" e "depois", aí é sinal.

**A lista é verificada na captura "antes" de cada rodada, e corrigida ali
mesmo.** Entrada que voltou a responder 200 sai desta lista no mesmo commit; ruído
que apareceu, entra. "Ruído conhecido" que envelhece manda ignorar um 500 que, se
voltar, é regressão de verdade — e essa é a única defesa contra isso.

### Duas rotas divergem sempre, porque a captura escreve nelas

`/reports` lista os documentos gerados e `/versions` é o log de auditoria. A
própria varredura alimenta os dois: baixar histórico e boletim assinados cria um
registro por chamada, e cada `--role` grava `actual_role` no usuário, que o log
audita. O lado "depois" ganha linhas que o "antes" não tem, e elas são da rodada,
não da mudança.

São diferença de **conteúdo**, não de status, então não entram na lista acima.
Antes de investigar qualquer uma, olhe a autoria e o horário das linhas novas: se
forem da conta de captura, no intervalo da rodada, são pegada do instrumento.

### Não confunda template oculto com erro na tela

O active_scaffold deixa no DOM, **oculto**, um painel
`.error-message.message.server-error` com o texto "Internal Error". Ler o
`innerText` dele sem checar visibilidade faz **qualquer** página parecer
quebrada: um "salvar devolve 500" pode ser esse painel invisível, com o registro
gravando e o servidor respondendo 302.

Ao sondar erro por Selenium, exija visibilidade:

```ruby
visivel = driver.execute_script(<<~JS)
  var e = document.querySelector('.error-message, .errorExplanation');
  return e && e.offsetParent !== null && getComputedStyle(e).display !== 'none'
    ? e.innerText.trim() : null;
JS
```

E cruze com a rede: sem resposta não-2xx no log de performance **e** sem 500 no
`log/production.log` do servidor, o erro está na sua sonda, não na aplicação.

## Regras de segurança

- **Somente leitura** durante as capturas. A escrita acontece nos passos 2, 4 e 6
  da ordem de execução, deliberada e sempre fora da janela entre as duas fotos.
- **Antes de disparar notificação**, rode o `simulate` e conte as mensagens.
  Notificação `individual` gera uma mensagem por linha do resultado — uma
  consulta ampla enche a caixa de quem recebe. As de prefixo `CORD` mandam um
  e-mail só.
- **A homologação envia e-mail de verdade.** Roda em ambiente **production**
  (não há `staging.rb`; entrega por `sendmail`, `should_send_emails = true`). O
  que impede vazamento é **uma** variável de banco, `CustomVariable.redirect_email`
  (tela *Configurações → Variáveis*), e ela vale tanto para notificações
  (`lib/notifier.rb`) quanto para o Devise (`app/mailers/devise_mailer.rb`).
  Tabela verdade — **confira o valor vivo antes de qualquer disparo**:
  - `""` (vazio) = trava mestra, **nada envia** (default do seed).
  - **`nil`** (variável ausente) = **PERIGO: envia ao destinatário real**. Não
    dispare nada neste estado.
  - **um endereço** = envia e **redireciona tudo** para ele; assunto ganha
    "(Originalmente para <real>)". É o estado seguro e verificável.
- **Ler o e-mail redirecionado:** tente o **Gmail via MCP primeiro** (`/mcp` →
  "claude.ai Gmail") para ler as mensagens e clicar nos links. Se não conectar,
  **peça ao usuário para colar** as mensagens que chegaram — o link de token vem
  no corpo e basta para prosseguir.
- **Reset de senha da conta de captura:** ao completar um reset de teste,
  redefina para o **mesmo valor** do env (`SAPOS_STAGING_PASS`) — trocar quebra o
  login dos scripts de captura.
- **Não repita um POST cujo resultado foi ambíguo.** `execute_now` responde 302
  sem corpo tanto em sucesso quanto em falha; confirme pela tela de notificações
  enviadas, não pela "Próxima Execução", que ele não altera.
- **Dado pessoal não sai do disco local.** As capturas contêm nome, e-mail e nota
  de aluno. Não versione os diretórios de captura, não cole trechos em issue ou
  PR, e descreva achados genericamente. Ao inspecionar, extraia as colunas de que
  precisa em vez de despejar a página inteira.

## Diferença esperada em PDF

Todo PDF vai acusar diferença, e quase sempre é benigna. O `compare_binary.rb`
já imprime a bounding box ao lado da contagem; para investigar uma página
específica à mão, localize **onde** os pixels mudaram:

```bash
magick \( antes.png -background white -flatten \) \
       \( depois.png -background white -flatten \) \
  -compose difference -composite -colorspace Gray -threshold 0 -format "%@" info:
```

O `-background white -flatten` não é opcional: os PNGs são `PaletteAlpha`, e sem
achatar sobre o branco o composite de diferença devolve uma bbox vazia
(`0x0+...`) — parece "sem diferença" numa página que mudou.

- Uma faixa estreita no rodapé (poucas centenas de px), na mesma posição em
  todas as páginas, é a hora de geração. Benigno.
- Nos documentos com assinatura digital (histórico e boletim), a área do QR code
  muda por inteiro a cada geração, porque cada chamada cria um registro novo com
  identificador próprio. Benigno — e lembre que **essas rotas escrevem**.
- Diferença espalhada pela página, ou em faixa larga fora do rodapé, merece
  inspeção visual: recorte a região nos dois lados e olhe.

```bash
magick antes.png -crop 560x110+80+1035 +repage /tmp/antes.png
```

Contagem de pixels sozinha engana: `compare -metric AE` imprime notação
científica (`4.5e+07`) e diverge de uma contagem real em PNG paletizado — por
isso o `compare_binary.rb` mede pela média do composite achatado, não pelo AE.
**Quando a contagem e a imagem discordarem, olhe a imagem**: é o que distingue
"QR code novo por desenho" de "regressão de renderização".

## Rota que dá 500 é sinal, não ruído

A varredura aciona o notificador de exceções da aplicação, então erro 500 vira
e-mail. Isso é desejável: foi assim que apareceram bugs pré-existentes. Não
remova rotas da lista só para silenciar o alerta — corrija a aplicação.
