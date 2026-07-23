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

- ImageMagick (`magick`, `compare`) e `unzip`.
- `chromedriver` compatível com o Chrome instalado. Se os feature specs
  começarem a falhar no baseline, provavelmente o Chrome se atualizou e o
  chromedriver ficou para trás.
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

```bash
set -a; source ~/.sapos_staging_env; set +a
S=.claude/skills/homologacao

bundle exec ruby $S/capture_html.rb   ~/capturas/antes-html   $S/routes_html.txt
bundle exec ruby $S/capture_html.rb   ~/capturas/antes-extra  $S/routes_extra.txt
bundle exec ruby $S/capture_binary.rb ~/capturas/antes-bin    $S/routes_binary.txt

# ... deploy da versão nova, e o mesmo com ~/capturas/depois-*

ruby $S/compare_html.rb   ~/capturas/antes-html  ~/capturas/depois-html
ruby $S/compare_html.rb   ~/capturas/antes-extra ~/capturas/depois-extra
ruby $S/compare_binary.rb ~/capturas/antes-bin   ~/capturas/depois-bin
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

## Como a comparação é feita

- **Texto de página** — hash do texto visível, com o rodapé de versão
  neutralizado. Datas **não** são normalizadas de propósito: mudança de formato
  de data é uma das regressões procuradas.
- **Screenshot** — PNG de página inteira, comparado pixel a pixel.
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

## Regras de segurança

- **Somente leitura** durante as capturas, exceto no passo 3, deliberado.
- **Antes de disparar notificação**, rode o `simulate` e conte as mensagens.
  Notificação `individual` gera uma mensagem por linha do resultado — uma
  consulta ampla enche a caixa de quem recebe. As de prefixo `CORD` mandam um
  e-mail só.
- **Confirme as duas travas do `lib/notifier.rb`** antes de qualquer disparo:
  `config.should_send_emails` e a variável `redirect_email`. Sem a segunda
  preenchida, o e-mail vai para os destinatários reais.
- **Não repita um POST cujo resultado foi ambíguo.** `execute_now` responde 302
  sem corpo tanto em sucesso quanto em falha; confirme pela tela de notificações
  enviadas, não pela "Próxima Execução", que ele não altera.
- **Dado pessoal não sai do disco local.** As capturas contêm nome, e-mail e nota
  de aluno. Não versione os diretórios de captura, não cole trechos em issue ou
  PR, e descreva achados genericamente. Ao inspecionar, extraia as colunas de que
  precisa em vez de despejar a página inteira.

## Diferença esperada em PDF

Todo PDF vai acusar diferença, e quase sempre é benigna. Antes de investigar,
localize **onde** os pixels mudaram:

```bash
magick antes.png depois.png -compose difference -composite \
  -colorspace Gray -threshold 0 -format "%@" info:
```

- Uma caixa de poucos pixels no rodapé, na mesma posição em todas as páginas, é
  a hora de geração. Benigno.
- Nos documentos com assinatura digital (histórico e boletim), a área do QR code
  muda por inteiro a cada geração, porque cada chamada cria um registro novo com
  identificador próprio. Benigno — e lembre que **essas rotas escrevem**.
- Diferença espalhada pela página, ou em faixa larga fora do rodapé, merece
  inspeção visual: recorte a região nos dois lados e olhe.

```bash
magick antes.png -crop 560x110+80+1035 +repage /tmp/antes.png
```

Contagem de pixels sozinha engana: `compare -metric AE` e uma comparação em RGB
podem discordar em PNG paletizado. Quando discordarem, olhe a imagem — foi assim
que se distinguiu "QR code novo por desenho" de "regressão de renderização".

## Rota que dá 500 é sinal, não ruído

A varredura aciona o notificador de exceções da aplicação, então erro 500 vira
e-mail. Isso é desejável: foi assim que apareceram bugs pré-existentes. Não
remova rotas da lista só para silenciar o alerta — corrija a aplicação.
