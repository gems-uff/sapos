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

A ordem importa. Escrita contamina a comparação, então vem por último.

1. **Deploy da versão atual de produção** em homologação.
2. **Captura "antes"** — os três conjuntos, em diretórios separados.
3. **Ações de escrita** que você queira exercitar (disparo de notificação, por
   exemplo), e **recaptura** dos conjuntos afetados, para que os dois lados
   reflitam o mesmo estado.
4. **Deploy da versão nova.**
5. **Captura "depois"**, idêntica.
6. **Comparação.**

Entre 2 e 5 o banco **não pode ser reimportado**. Uma réplica nova traria
edições feitas em produção no meio do caminho, e diferenças de dado apareceriam
como se fossem de código.

### Onde as capturas ficam

Tudo mora em `~/capturas-sapos-staging/`, **fora do repositório** (contêm dado
real — ver "Regras de segurança"). Uma pasta por versão capturada, nomeada
`<data>_v<versão>_<rótulo>`, com `html/`, `extra/` e `bin/` dentro:

- `<data>` — dia da captura (`AAAA-MM-DD`), para ordenar cronologicamente.
- `<versão>` — a do rodapé (`Versão 7.15.21-27-gc0e804a2`), que identifica o
  código exato.
- `<rótulo>` — o que aquela versão é (`producao`, `rails72`, `security_updates`).

As pastas antigas ficam ali como arquivo das rodadas anteriores; não as apague ao
começar uma nova. Cada rodada compara duas dessas pastas — a "antes" e a "depois".

```bash
set -a; source ~/.sapos_staging_env; set +a
S=.claude/skills/homologacao
CAP=~/capturas-sapos-staging

# Ajuste as duas versões à rodada. Nomeie pela versão do rodapé de cada deploy.
ANTES=$CAP/2026-07-22_v7.15.20_producao
DEPOIS=$CAP/2026-07-24_v7.15.21-27-gc0e804a2_security_updates

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

- **Texto de página** — hash do texto visível, com o rodapé de versão
  neutralizado. Datas **não** são normalizadas de propósito: mudança de formato
  de data é uma das regressões procuradas.
- **Screenshot** — PNG de página inteira, comparado pixel a pixel, porque texto
  igual não é tela igual: asset que sumiu, CSS que quebrou e layout deslocado não
  mudam uma letra do texto visível. A saída **agrupa as páginas pela bounding box
  da diferença**, e é assim que se lê: a string de versão está em toda página, na
  mesma posição, então ela vira um grupo único com quase tudo dentro — e o que
  divergiu por outro motivo sobra em grupo próprio, no topo (a ordem é por área).
  Numa rodada real, 125 páginas colapsaram em três linhas. Nenhuma coordenada
  fica escrita no script: neutralizar a faixa da versão por coordenada fixa
  quebraria com outro tema, zoom ou resolução.
- **PDF** — rasterizado em PNG por página. Comparar bytes não funciona: PDF
  embute data de criação, então o mesmo relatório gerado duas vezes já tem hash
  diferente.
- **XLSX** — descompactado; o diff é no XML interno, ignorando `docProps/core.xml`.
- **Status HTTP, erros de console e requisições que falharam** — de onde vêm os
  sinais mais baratos. Quebra de upgrade costuma ser 500, e asset faltando
  aparece como 404 de rede.

## Verifique o instrumento, não só o sistema

Um comparador quebrado também devolve "nenhuma diferença". O `compare_html.rb`
imprime, ao final, quantas páginas diferem **sem** normalizar: como as duas
versões têm strings de versão diferentes, esse número tem que ser alto. Se ele
vier zero junto com o resultado principal, desconfie da comparação antes de
concluir que não houve regressão.

Isso não é hipotético: a primeira versão dessa checagem estava errada e devolvia
zero para um par que sabidamente diferia.

A mesma armadilha pegou a medição de imagem, e de um jeito que só aparece quando
**não** há diferença: a bounding box de uma diferença vazia é indefinida, e o
`magick` avisa no stderr antes de imprimir `0 0x0+...`. O padrão ancorado em `\A`
lia o aviso, não casava, e reportava "falha ao medir" — ou seja, a página
**idêntica** era a única que o comparador não sabia classificar. Por isso a
contagem de páginas alteradas por pixel tem checagem de sanidade própria: com
duas versões diferentes, zero ali é comparador quebrado, não ausência de
regressão.

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
substitui a estática. Roteiro-modelo e um harness Selenium reusável (login lendo a
env var + helpers de screenshot) ficaram de uma rodada real em
`~/capturas-sapos-staging/2026-07-24_*_security_updates/` (`roteiro-exploratorio.md`
+ `exploratorio/harness/`) — use como ponto de partida. Regras: só `new`/`edit`
**sem salvar** onde der; a única escrita persistida é em tabela de apoio com rótulo
`ZZ-TESTE-HOMOLOG`, apagada ao fim; e-mail só com a trava `redirect_email`
conferida. A extensão do Chrome pode estar indisponível — o harness Selenium
headless + screenshots avaliadas por visão contorna isso.

## Preparando o ambiente para o papel de aluno

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

Medido na `main` (7.15.23) em 27/07/2026, presente também no baseline anterior:

- `/form_autocompletes/form_field` responde **500**. Causa no código do app:
  `Admissions::FormField.full_search_name` tem `field:` com default `nil` e cai
  em `name.include?(field)` — `TypeError: no implicit conversion of nil into
  String`. A varredura chama a rota sem parâmetro, que é exatamente esse caso.

Aparece nos dois lados da comparação e deve ser ignorado como achado — mas se
**mudar** de status entre "antes" e "depois", aí é sinal.

### Não confunda template oculto com erro na tela

O active_scaffold deixa no DOM, **oculto**, um painel
`.error-message.message.server-error` com o texto "Internal Error". Ler o
`innerText` dele sem checar visibilidade faz qualquer página parecer quebrada —
e já custou um diagnóstico inteiro aqui: "salvar Aluno devolve 500" era esse
painel invisível, com o registro gravando e o servidor respondendo 302.

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

- **Somente leitura** durante as capturas, exceto no passo 3, deliberado.
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
(`0x0+...`) — parece "sem diferença" numa página que mudou. Foi um dos dois bugs
que o `compare_binary.rb` carregou.

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
Quando a contagem e a imagem discordarem, olhe a imagem — foi assim que se
distinguiu "QR code novo por desenho" de "regressão de renderização".

## Rota que dá 500 é sinal, não ruído

A varredura aciona o notificador de exceções da aplicação, então erro 500 vira
e-mail. Isso é desejável: foi assim que apareceram bugs pré-existentes. Não
remova rotas da lista só para silenciar o alerta — corrija a aplicação.
