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
mecânicas de uma vez:

```
.claude/skills/merge-downstream/conferir_merge.sh [commit-de-merge] [ref-de-cima]
```

Sem argumentos, confere o `HEAD` contra a `main`. Serve tanto depois de mergear
quanto para auditar merge alheio. O que segue explica cada seção e o que fazer
com o resultado.

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
git rev-list --left-right --count main...origin/<ramo>   # atrás / à frente
git log --oneline origin/<ramo>..main                    # o que vai entrar
git diff --numstat origin/<ramo>...main                  # em que arquivos
```

Cruze a lista de arquivos que a `main` mexeu com a dos que o ramo mexeu. A
interseção é onde pode haver conflito de verdade — e é onde olhar primeiro
depois.

Ensaie antes de mergear. `git merge-tree --write-tree` reconstrói o merge sem
tocar na árvore de trabalho: código de retorno zero quer dizer que não há
conflito textual nenhum.

## Depois: o que o humano digitou

**`git diff-tree --cc` não serve para isso.** Ele lista todo arquivo que difere
de *ambos* os pais, o que é o normal de qualquer arquivo mesclado dos dois lados
— um merge sem uma única edição manual pode aparecer ali com dezenas de arquivos.
Usar o `--cc` como detector de edição manual gera lista enorme e sem sinal.

O que isola de verdade é reconstruir o merge automático e comparar com a árvore
que ficou gravada:

```
AUTO=$(git merge-tree --write-tree <pai1> <pai2> | head -1)
git diff $AUTO <merge>^{tree}
```

Diff vazio: ninguém digitou nada. Diff não vazio: o que sobrou foi digitado por
alguém, e aí vale ler. O sinal de resolução que **perdeu** conteúdo é hunk só de
remoção num arquivo que o lado de cima tinha acabado de acrescentar — pior ainda
quando a linha perdida nem estava na região do conflito, o que indica que o
arquivo inteiro foi substituído por uma das versões em vez de mesclado.

Para saber se alguma coisa do lado de cima se perdeu, olhe a diferença líquida
contra o **pai 2** (não contra o topo atual da `main`, que já andou). Arquivo que
só acrescenta linha não pode ter perdido nada; a atenção vai para os que removem.
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

Achando um, o conserto é ressincronizar com a versão em uso reaplicando a
mudança própria — e **deixar uma guarda**, senão o próximo upgrade repete tudo.
`spec/lib/active_scaffold_overrides_spec.rb` é o modelo: a cópia só pode
acrescentar linhas ao original, então toda linha do original aparece nela na
mesma ordem; linha que a gem mude some da sequência e o teste falha no upgrade,
que é quando ainda dá para decidir.

## O `Gemfile.lock`

Merge textual de lock pode produzir arquivo incoerente, e é a preocupação certa.
Mas **não regenere o lock do zero.** Apagar e reinstalar equivale a um
`bundle update` em tudo: sem lock não há versão nem SHA fixados, a resolução vai
ao topo do que cada restrição permite, e dependência que vem de ramo de fork
passa a apontar para o *head* daquele ramo. `bundle install` sozinho nunca sobe
versão — ele reproduz o lock e instala o que falta.

A conferência certa não muda nada:

```
bundle lock --print | diff Gemfile.lock -   # vazio = o lock ja e o que o bundler resolveria
bundle check                                # so acusa o que falta instalar
```

E compare as versões contra o lado de cima: o resultado saudável de um merge de
catch-up é **só acréscimo** — as gems que o ramo introduziu, mais as transitivas
delas. Qualquer versão *diferente* de uma gem que os dois lados já tinham merece
explicação.

## Fechamento

Suíte inteira, sem `SKIP_COVERAGE=1`, como manda o `AGENTS.md`. Mas com uma
ressalva que vale gravar: **suíte verde não prova ausência de conflito
semântico.** Já aconteceu de a suíte inteira fechar verde com uma cópia de
partial desatualizada em vigor — o que a cópia desfazia não tinha asserção que o
notasse. A suíte fecha o merge; quem procura conflito semântico são as
verificações acima.
