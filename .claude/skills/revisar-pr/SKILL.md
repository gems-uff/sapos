---
name: revisar-pr
description: Conduz um PR do repositório do começo ao fim — ler a issue e o diff, decidir o que é nosso e o que volta para o autor, cobrir o que falta de teste, medir, homologar e lançar. Use ao dizer "vamos trabalhar no PR N", ao revisar contribuição de terceiro, ou ao retomar um ramo parado.
---

# Trabalhar num PR

Esta skill é a **espinha**: ela diz *quando* cada coisa entra e *por quê*. O *como*
está nas skills apontadas, e não se repete aqui — passo que cabe numa frase mais um
ponteiro é uma frase mais um ponteiro.

**Nem todo PR termina em release.** As quatro saídas legítimas estão no passo 4; a
linha reta até o lançamento é uma delas, não a única. Os passos 6 a 8 pertencem só
a ela e o 9 vale nas quatro; o 5 é dos dois lados — na linha reta cobre as
lacunas, e ao devolver põe a reprodução em forma de spec do projeto. Veredito
plausível também atravessa: manda medir em MariaDB ou homologar antes de fechar
qualquer saída.

## Onde cada sinal leva

| O que aparece no diff ou no ramo | Skill que entra |
|---|---|
| `Gemfile` / `Gemfile.lock` | `dependencias` |
| SQL, unicidade, ordenação, migration | `suite-mariadb` |
| Asset, tela, PDF, planilha, e-mail | `homologacao` |
| Ramo atrás da `main` | `merge-downstream` |
| Suspeita de defeito no diff | `provar-candidato` |
| Qualquer mudança que precise ser medida | `safe-refactor` |
| Tudo verde e homologado | `release` |

## 1. Reconhecimento

O `gh pr checkout` troca de ramo: com modificação sua nos arquivos que o PR toca
o git recusa a troca inteira, então comece com a árvore limpa. Havendo trabalho
não commitado ali, **pare e pergunte ao mantenedor** antes de trocar: pelo
`AGENTS.md` é ele quem commita, e mudança não commitada não tem reflog de onde
voltar.

O `--force` não é opcional: sem ele, num PR que sofreu force-push, o `git merge
--ff-only` que o gh roda por dentro aborta enquanto o checkout sai com sucesso, e
você passa o ciclo inteiro medindo um ramo obsoleto. Ele reseta o ramo local —
confira antes que não haja commit seu ali.

```bash
gh pr view <N> --json title,state,headRefName,mergeable,commits,statusCheckRollup,isCrossRepository,maintainerCanModify
git fetch --all --prune
gh pr checkout <N> --force                  # tudo daqui para a frente lê a árvore
git log --oneline origin/main..HEAD         # o que o PR traz
git log --oneline HEAD..origin/main         # o que falta da main entrar
```

A segunda lista vazia é o que se quer. Se não estiver, `merge-downstream` antes de
qualquer medida: base desatualizada mede a defasagem, não o PR.

PR de fork traz o ramo num remote do autor: o `maintainerCanModify` do `gh pr
view` acima diz se o mantenedor consegue empurrar ali a reprodução que o passo 3
prepara. Sem ele, ela só chega ao autor por comentário.

**Leia a issue e os comentários dela, não só o título**, e também os das issues
relacionadas e fechadas. É neles que está a decisão de produto já tomada, a
tentativa revertida e o que já foi homologado antes; sem isso é fácil tratar como
novo um trecho já validado, ou refazer discussão encerrada.

Dispare o `/code-review xhigh <N>` e siga o passo 2 enquanto ele roda — o
número do PR lhe dá também os comentários do autor.

- **`xhigh`, não menos:** abaixo disso ele pode cair numa variante de passada
  única, sem a varredura final de lacunas.
- **Nunca `--comment` nem `--fix`.** O primeiro publica no PR; o segundo aplica
  na árvore fora dos checkpoints, e `/rewind` não desfaz.
- Ele não verifica o que devolve, e o fim da lista costuma ser piso de achados,
  não descoberta. Quem tria é o passo 3.

## 2. Ler o diff

**Diga primeiro que tipo de PR é este** e declare as diferenças esperadas antes de
rodar qualquer medida. Os critérios estão no passo 8 da `safe-refactor` — correção
de bug, feature e refatoração —, e **upgrade se interpreta como refatoração**:
dele também se espera diferença nenhuma.

**Leia o diff você mesmo, e anote os seus candidatos** — não delegue isto ao
`/code-review`. Ele cruza arquivos e confronta o diff com a convenção escrita, mas
não sai do repositório: quatro classes de candidato **só saem da sua leitura**,
porque dependem do que o repositório não guarda:

- **O efeito nas instalações reais** — quantas consultas gravadas param de casar
  com o esquema, quantas notificações dependem delas, quais têm disparo agendado.
  É o achado de maior peso que uma revisão produz, e você não alcança as
  instalações: passe ao mantenedor um prompt para rodar onde elas são
  alcançáveis, dizendo em que coluna a migration mexe e pedindo de volta as
  consultas cujo SQL cita essa coluna. **Não peça `rake queries:check` agora**: ele valida contra o
  esquema da instalação, que ainda é o de antes da migration, e o verde que ele
  devolve não significa nada. Essa rodada é a de depois, e está no passo 8.
- **A cobertura que a issue pede**, e não a que existe: a máquina só reclama de
  teste ausente como nit, e não sabe o que a issue prometeu.
- **Decisão de produto**, inclusive sobre o pedido que você mesmo fez ao autor.
  Não é achado, é julgamento, e retratar-se em público é parte do trabalho.
- **O que o merge vai encontrar** — qual spec da `main` deixa de compilar contra a
  modelagem nova. Os dois lados passam verdes em separado, e só a suíte completa
  depois do merge acusa; o detalhe está na `merge-downstream`. Vale também com o
  ramo em dia, então não espere o roteamento do passo 1 para olhar.

Quando o PR mexe no `Gemfile`, o que decide a revisão é o que mudou **na
dependência**, não o que o autor escreveu: valem as notas do passo 1 da
`safe-refactor`. O que é próprio da revisão é conferir **o ajuste do autor contra
o guia da lib** — instrução de migração vem em prosa, e é o item que passa
despercebido e só quebra no deploy.

## 3. Triar os candidatos

Os seus e os do `/code-review`, todos pela `provar-candidato`: a escalada, os três
vereditos e as regras da prova estão lá.

O que é próprio da revisão de PR é **onde fica o "antes": no merge-base, não na
`main`** — ramo atrasado mediria o PR somado ao que a `main` andou. Worktree em
`git merge-base origin/main HEAD`, `cp config/database.yml.example
config/database.yml` (o real não é versionado, e sem ele o ambiente não sobe),
`bundle install` (o `Gemfile.lock` de lá pode não ser o seu — e num PR de
dependência ele nunca é) e `rake db:schema:load`. É também como se descobre que **um candidato já valia antes
do PR**: não é regressão, e a mensagem ao autor muda de "você quebrou" para "isto
piorou aqui, conserta agora ou vira issue?".

Crie a worktree **fora** do repositório e remova-a com `git worktree remove` ao
fechar o passo 6: dentro dele ela derruba a precondição de árvore limpa da
`release`, e esquecida acumula uma por PR — a `release` confere `git status`,
nunca `git worktree list`.

## 4. De quem é o conserto?

É a decisão central da skill, e ela tem quatro saídas.

**Assumimos nós, e seguimos** quando o PR está majoritariamente adequado: os
consertos do autor atacam a causa, o que falta é **aditivo** (teste que ninguém
escreveu, cobertura de um caminho novo) e não há decisão de produto em disputa.
Comentar no PR nesse caso só adia por dias um trabalho que já está pronto na
árvore.

**Comenta no PR e devolve** quando há retrabalho: a correção trata o sintoma no
lugar da causa, o número de ajustes reescreveria os commits do autor, ou falta
contexto que só ele tem.

**Para e pergunta ao mantenedor** quando a dúvida é de produto, não de código.

**Não segue** quando o PR contraria decisão já tomada, duplica issue fechada, ou
está obsoleto a ponto de o merge custar mais que refazer. Sai da leitura do passo
1, e é a conclusão de maior valor que uma revisão produz — a que evita todo o
resto do ciclo. Fechar PR de terceiro é decisão do mantenedor: leve o motivo e o
que sustenta.

**Ao devolver, mande as reproduções junto — não só a prosa.** As do passo 3 já
afirmam o comportamento correto e falham enquanto o defeito existir, e no ramo do
autor deixariam a suíte dele vermelha até o conserto. Isso é mais útil que
descrição, e não é acusação: a reprodução **é a especificação do conserto**, e vale
dizer isso no comentário. Commit e push são do mantenedor — deixe a reprodução
pronta na árvore e peça. Em ramo do próprio repositório ele empurra; em fork, só
se o `maintainerCanModify` deixar.

Duas condições. A reprodução vai limpa, com nome e lugar de spec do projeto, sem
resquício do script exploratório que a gerou. E **feedback em uma rodada**: junte
tudo — confirmados, refutados, o que não é regressão e o que ficou em aberto — em
vez de comentar achado a achado, que faz o autor perseguir alvo móvel.

**Vulnerabilidade introduzida pelo próprio PR pode ser discutida nele**, porque
não há sistema no ar exposto: o defeito nasce no merge. Já a pré-existente, achada
de passagem, segue a regra do `AGENTS.md` — correção imediata, sem issue pública.

Duas coisas que **não** justificam devolver, e viram registro escrito: desvio de
convenção de mensagem de commit, e achado adjacente fora do escopo do PR — este
vira issue própria (pesquise as existentes antes, inclusive fechadas).

## 5. Cobrir as lacunas

A cobertura nova é só do caminho "assumimos nós", e por isso depois do passo 4:
escrita antes da decisão, ela se perde se o PR voltar para o autor. As
reproduções do passo 3 são outra coisa — essas já existem, e são elas que viajam;
ao devolver, é aqui que elas ganham forma de spec do projeto, pelas regras
abaixo.

O que a mudança toca e a suíte não executa vira teste, pela `safe-refactor` —
inclusive a checagem de que o teste não é vazio. O que nem a suíte alcança vira
sonda, pela `homologacao`.

Revisão inverte a ordem da `safe-refactor`: a mudança **já existe**, então não dá
para escrever o teste contra o código velho. A saída é escrever contra o
comportamento novo e provar o vermelho **simulando a versão anterior** — com o
código dela, nunca com uma aproximação escrita à mão.

**A reprodução também tem de ficar verde quando o defeito sair.** O vermelho de
hoje prova que ela alcança o defeito; só o controle prova que ela é satisfazível
— desligue a linha culpada e confira que passa. Sem isso viaja asserção que
nenhum conserto atende, e o autor perde a rodada tentando: linha de gabarito
entrando na contagem, ordem que o navegador não garante, mensagem de erro citada
ao pé da letra.

**Reprodução de rodada anterior volta a ser suspeita.** Rode as antigas antes de
ler o diff novo, e para cada uma que passou pergunte *por que* passou: o defeito
foi consertado, ou o conserto abriu caminho que devolve antes de chegar ao ponto
medido? Guarda de precondição, `return` de estado vazio e autorização avaliada
sobre a classe em vez da instância deixam o exemplo verde sem tocar no que ele
guardava. O teste é o mesmo de sempre: desligue a linha do conserto e confira que
o exemplo cai. Quem passava pelo motivo errado se reescreve — e junto com ele o
comentário que descrevia o defeito no presente, senão a rodada seguinte lê a
descrição como se o defeito ainda estivesse lá.

## 6. Medir

Suíte completa pela `safe-refactor`, comparada à baseline. Confira também o CI na
ponta do ramo: ele roda o que a máquina local não roda, e roda em MariaDB — é a
medida que alcança os pontos cegos que o `AGENTS.md` lista. A contagem de exemplos
dele é maior que a local; compare-a com a do CI na baseline, não com a sua.

**`gh pr checks <N>` sai com código não-zero enquanto há check pendente** (e
também quando algum falha), então tratar saída não-zero como erro transitório a
engolir faz o laço de espera girar calado, e o silêncio fica indistinguível de
"ainda rodando". Pendente *é* o estado, não uma falha ao consultá-lo: decida pelo
texto da saída, nunca pelo código de retorno.

`suite-mariadb` quando o diff toca SQL, unicidade, ordenação ou migration; verde
em SQLite não diz nada sobre esses pontos. Migration que mexe em coluna pede
também `rake seeds:check` — o porquê está na mesma seção do `AGENTS.md`.

## 7. Homologar

`homologacao`, quando a mudança toca o que a suíte estruturalmente não alcança —
adaptador de banco, geração de PDF e planilha, renderização de tela, pipeline de
assets, e-mail. Ela inclui a passada de escrita nos dois lados: a comparação
sozinha é toda de leitura.

## 8. Lançar

`release`. Antes de chamá-la, isto tem de ser verdade: suíte completa verde no
ramo, homologação feita quando cabia, `main` sincronizada, árvore de trabalho
limpa e CI verde na ponta.

Migration que mexe em coluna deixa uma pendência **para depois do deploy**: `rake
queries:check` em cada instalação, já com o esquema migrado. É a única rodada que
acusa consulta gravada quebrada — a de antes é verde por construção. Registre a
pendência onde o mantenedor a encontre; consulta quebrada só se manifesta quando
alguém abre o relatório ou a notificação dispara.

## 9. Fechar o rastro

Cada aprendizado tem um lugar, e o critério é o do `AGENTS.md`, na seção "Skill é
procedimento, não diário de bordo".

Uma obrigação antes de considerar o PR encerrado: **conclusão sua que caiu por
evidência nova se corrige onde foi escrita.** Se virou mensagem de commit ainda
não empurrada, reescreva o commit — o teste pode sobreviver com outro
enquadramento, a justificativa errada não pode virar história.
