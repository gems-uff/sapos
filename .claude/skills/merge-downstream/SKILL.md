---
name: merge-downstream
description: Traz a main para dentro de um ramo de issue e confere se ela entrou inteira — inclusive o que o git não vê. Use ao atualizar um ramo atrasado, ao revisar merge que outra pessoa fez, ou antes de aceitar um ramo para release.
---

# Merge da main para o ramo

Trazer a `main` para um ramo de issue é rotina, e por ser rotina passa por
automático. Duas coisas dão errado calado: **conteúdo da main que se perde na
resolução de um conflito** e **incompatibilidade que só existe depois do merge**,
que o git não tem como enxergar. As duas se detectam por medida, não por leitura.

O script `conferir_merge.sh`, na pasta desta skill, roda as verificações
mecânicas de uma vez, de qualquer ponto do checkout:

```
"$(git rev-parse --show-toplevel)"/.claude/skills/merge-downstream/conferir_merge.sh [commit-de-merge] [ref-de-cima]
```

Sem argumentos, confere o `HEAD` contra a `origin/main`, nunca contra a `main`
local, que o `git fetch` não avança (ver a seção seguinte). Supõe o merge feito
no ramo (`git merge origin/main`): pai 1 é o ramo, pai 2 o lado de cima. Serve tanto depois de
mergear quanto para auditar merge alheio. O código de retorno não é veredito (0
depois do relatório, 1 quando recusa os argumentos); o que pede leitura vem
marcado `ATENCAO`. Precisa de git 2.38 ou mais novo (`merge-tree --write-tree`).
O que segue explica cada seção e o que fazer com o resultado.

## O merge é seu; o conflito semântico também

**Conflito não é só sobreposição de texto.** Os dois lados podem estar corretos
isolados, o texto não se sobrepor em lugar nenhum, o git não acusar nada — e a
combinação estar quebrada. Isso é conflito semântico, e ele **nasce no merge**:
antes dele o defeito não existia em lugar nenhum.

Daí a consequência prática: **quem faz o merge resolve, antes do push.** Não vira
item na lista de pendências de quem escreveu o código, porque não havia defeito
no código de ninguém. Vale corrigir em commit próprio, sobre o merge, com a
explicação na mensagem — o merge continua verificável contra o merge automático,
e quem ler depois entende por que aquele conserto apareceu do nada.

## Antes: medir a distância

```
git fetch origin
git rev-list --left-right --count origin/main...HEAD   # atrás / à frente
git log --oneline HEAD..origin/main                    # o que vai entrar
git diff --numstat HEAD...origin/main                  # em que arquivos
```

Tudo contra `origin/main` e `HEAD`, nunca contra a `main` local nem contra
`origin/<ramo>`: o `git fetch` não avança a `main` local, e ramo vindo de fork
não tem `origin/<ramo>` nenhum — se a origin tiver um homônimo, os três comandos
resolvem contra o ramo errado sem reclamar.

Cruze a lista de arquivos que a `main` mexeu com a dos que o ramo mexeu. A
interseção é onde pode haver conflito de verdade — e é onde olhar primeiro
depois.

Ensaie antes de mergear. `git merge-tree --write-tree --name-only HEAD
origin/main` reconstrói o merge sem tocar na árvore de trabalho: código de
retorno zero quer dizer que não há conflito textual nenhum; com conflito, a
primeira linha continua sendo a árvore e as seguintes nomeiam os arquivos
conflitados.

No mesmo ensaio, procure a reprodução que a `main` guarda para a issue do ramo
(`git grep -n 'pending: "issue #NNN"' origin/main -- spec`, com o número do
ramo): é o que vai ficar vermelho depois do merge se o ramo consertou o defeito
— ver "O que o git não vê".

## Depois: o que o humano digitou

**`git diff-tree --cc` não serve para isso.** Na forma de lista (`--name-only`)
ele aponta todo arquivo que difere de *ambos* os pais, o que é o normal de
qualquer arquivo mesclado dos dois lados — lista sem sinal. Na forma de patch,
mostra só os hunks que não batem com nenhum dos pais. E nas duas formas deixa de
fora todo arquivo igual à versão de um dos lados: a resolução que trocou o
arquivo inteiro pela versão de um lado — justamente a que perde conteúdo — nunca
aparece ali.

O que isola de verdade é reconstruir o merge automático e comparar com a árvore
que ficou gravada:

```
AUTO=$(git merge-tree --write-tree <pai1> <pai2> | head -1)
git diff $AUTO <merge>^{tree}
```

Diff vazio: ninguém digitou nada. Diff não vazio: o que sobrou foi digitado por
alguém, e aí vale ler. Quando os pais conflitam, a árvore reconstruída traz os
marcadores de conflito, então o diff *é* a resolução. Dois conflitos escapam
dele, e o script procura os dois:

- **Marcador de conflito commitado** aparece como linha `<<<<<<<` e `>>>>>>>` no
  arquivo gravado, e só lendo o arquivo se acha: a reconstrução rotula os
  marcadores com o SHA dos pais e o `git merge` com `HEAD` e o nome da ref, então
  as duas versões nunca saem iguais e o arquivo cai no diff como mais uma
  resolução.
- **Conflito binário ou modify/delete não tem marcador**: a reconstrução já traz
  a versão de um dos lados, e a resolução que a manteve deixa o diff vazio
  naquele arquivo, com a mudança do outro lado sumida — inclusive a remoção que
  o ramo fez de um arquivo que a `main` alterou.

O sinal de resolução que **perdeu** conteúdo é hunk só de remoção num arquivo
que o lado de cima tinha acabado de acrescentar — pior ainda quando a linha
perdida nem estava na região do conflito, o que indica que o arquivo inteiro foi
substituído por uma das versões em vez de mesclado.

## Quando o pai 2 não parece a main

Antes de acusar o merge, confira se a estranheza não é do processo de release
daqui. Ele é **fast-forward puro** (ver a skill `release`): a `main` nunca recebe
merge, ela é avançada por cima do ramo — que, esse sim, tinha mergeado a `main`
dentro de si. Cada fast-forward **redireciona a cadeia de primeiro pai da
`main`** para dentro daquele ramo, e o que era topo da `main` passa a ficar do
lado do segundo pai.

A consequência engana: `git log --first-parent main` deixa de mostrar commits que
foram topo da `main` de verdade. Um merge legítimo, feito quando aquele commit
era o topo, passa a parecer que mergeou um ramo qualquer — e às vezes o commit
ainda por cima se chama "Merge branch 'main' into issue_NNN" de **outra** issue,
o que reforça a impressão errada.

Duas perguntas resolvem, e nenhuma delas é o `--first-parent`:

```
git merge-base --is-ancestor <pai2> origin/main   # aquilo chegou a estar na main?
git reflog show origin/main                # o que a ref apontava, e quando
```

O reflog data cada janela, então dá para dizer se o merge pegou o topo da hora ou
uma versão já vencida — e quanto tempo de atraso, que é a informação que
interessa.

Para saber se alguma coisa do lado de cima se perdeu, olhe a diferença líquida
contra o **pai 2** (não contra o topo atual da `main`, que já andou). Arquivo que
só acrescenta linha não pode ter perdido nada; a atenção vai para os que removem
— e para os binários, que não têm contagem de linha.
Para cada um, pergunte se o lado de cima mexeu naquele arquivo desde a
bifurcação — a base é `git merge-base <pai1> <pai2>`. Se não mexeu, a remoção é
do próprio ramo e está tudo bem.

## O que o git não vê

Depois de verde no textual, procure a incompatibilidade nova. Os lugares onde ela
mora neste projeto:

- **Arquivo do ramo que sombreia arquivo de gem.** Cópia de partial em
  `app/views/*_overrides/` é o caso clássico: existe só de um lado, então não há
  o que mesclar, e o upgrade da gem que vem pela `main` muda o original enquanto a
  cópia fica parada — desfazendo, calada, a parte do upgrade que tocou naquele
  arquivo. E o alcance costuma ser maior que o pretendido: override de partial de
  subform vale para todo subform do sistema, não só para a tela em que se estava
  pensando. O script sinaliza esse caso comparando cada arquivo novo do ramo com
  os arquivos das gems instaladas.
- **Monkey-patch em `config/initializers/`** que reabre classe interna de gem —
  o `AGENTS.md` lista quais são. Upgrade de gem pela `main` é exatamente o gatilho.
- **Classe de CSS ou de HTML gerada pela gem** e usada pelo JS ou pelo SCSS do
  ramo. Se a gem mudou o padrão de nome, o seletor deixa de casar sem erro
  nenhum.
- **Método de gem que o ramo passou a chamar.** Compare a assinatura entre a
  versão em que o ramo foi escrito e a que a `main` trouxe. Cuidado ao comparar
  com `grep -A`: a janela pega o método vizinho e acusa diferença onde não há.
- **Spec que a `main` trouxe contra modelagem que o ramo mudou.** Os dois lados
  passam separados — o spec novo não conhece a modelagem do ramo, e a suíte do
  ramo não tinha esse spec —, e só a suíte completa depois do merge acusa. Vale
  também para o ramo que já está em dia: "em dia" é afirmação sobre o instante
  da medida, e o spec pode chegar na `main` depois dela. Aqui não há versão a
  ressincronizar: decida quem está certo, o spec ou a modelagem, e conserte o
  lado errado antes do merge.
- **Pending da `main` que o ramo conserta.** Pela convenção do `AGENTS.md`, a
  reprodução de defeito vive na `main` com `pending: "issue #NNN"`; o ramo
  conserta a NNN sem conhecer essa reprodução. Depois do merge o exemplo passa, e
  o RSpec acusa o pending que passou ("Expected pending … to fail") — vermelho
  que não existia em nenhum dos dois lados. A marca sai no próprio merge ou num
  commit logo depois; o exemplo fica, como regressão, e o controle do cenário,
  que já entrou sem `pending`, não muda. Entrega pela metade é a exceção: o
  cenário que o ramo não conserta mantém a marca. O `git grep` de antes do merge
  mostra o que vai cair, e o script repete a busca no merge com as issues que
  acha no assunto dos commits do ramo.

Achando um dos quatro primeiros, o conserto é ressincronizar com a versão em uso
reaplicando a mudança própria — e **deixar uma guarda**, senão o próximo upgrade
repete tudo. Para cópia de partial, a guarda é um spec que confere a cópia contra
o original da gem instalada: a cópia só pode acrescentar linhas ao original,
então toda linha do original aparece nela na mesma ordem; linha que a gem mude
some da sequência e o teste falha no upgrade, que é quando ainda dá para decidir.

## O `Gemfile.lock`

Merge textual de lock pode produzir arquivo incoerente, e é a preocupação certa.
Mas **não regenere o lock do zero.** Apagar e reinstalar equivale a um
`bundle update` em tudo: sem lock não há versão nem SHA fixados, a resolução vai
ao topo do que cada restrição permite, e dependência que vem de ramo de fork
passa a apontar para o *head* daquele ramo. `bundle install` sozinho nunca sobe
versão — ele reproduz o lock e instala o que falta.

Quando o git deixa marcador de conflito no lock, o Bundler se recusa a lê-lo
("contains merge conflicts") e sugere `git checkout HEAD -- Gemfile.lock`. **Não
siga a sugestão:** no `git merge origin/main` feito no ramo, `HEAD` é o ramo, e
o lock dele descarta tudo o que a `main` subiu. Pegue o lado de cima — `git
checkout --theirs Gemfile.lock`, porque ali "theirs" é a `main` — e só então
`bundle install`, que mantém cada versão travada e acrescenta o que o `Gemfile`
mesclado exige. Isso derruba as versões que o próprio ramo tinha subido, e nada
reclama. Liste-as antes do merge:

```
v() { git show "$1:Gemfile.lock" | grep -oE '^    [A-Za-z0-9_.-]+ \([0-9][^)]*\)' | sort -u; }
comm -13 <(v $(git merge-base HEAD origin/main)) <(v HEAD)   # o que o ramo subiu
```

E refaça esses passos depois dele, com o mesmo comando que o ramo usou (a skill
`dependencias` diz qual), até cada versão voltar à do ramo.

A conferência certa não muda nada:

```
bundle lock --print | diff Gemfile.lock -   # vazio = o lock ja e o que o bundler resolveria
bundle check                                # so acusa o que falta instalar
```

O script só roda essa conferência quando o merge auditado é o `HEAD` e o
`Gemfile` e o `Gemfile.lock` estão limpos na árvore: o Bundler lê o lock da árvore
de trabalho, não o do commit, e fora disso mediria outro arquivo.

E compare as versões contra o lado de cima: o resultado saudável de um merge de
catch-up é **só o que o ramo travou** — as gems que ele introduziu ou subiu, mais
as transitivas delas. Versão que nenhum dos pais tinha, ou versão que os dois
tinham e o merge trocou, merece explicação; o script marca cada linha contra o
lock do ramo. O caminho inverso também conta: versão que um lado subiu desde a
bifurcação e o merge não tem mais é conteúdo perdido sem conflito nenhum — o
diff contra o merge automático não a pega quando a resolução pegou o lock de um
lado inteiro, e o script a lista.

## Fechamento

Suíte inteira, sem `SKIP_COVERAGE=1`, como manda o `AGENTS.md`. Mas com uma
ressalva que vale gravar: **suíte verde não prova ausência de conflito
semântico.** Cópia de partial desatualizada passa verde: o que ela desfaz do
upgrade raramente tem asserção que o note. A suíte fecha o merge; quem procura
conflito semântico são as verificações acima.
