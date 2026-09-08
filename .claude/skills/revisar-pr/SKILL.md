---
name: revisar-pr
description: Conduz um PR do repositório do começo ao fim — ler a issue e o diff, decidir o que é nosso e o que volta para o autor, cobrir o que falta de teste, medir, homologar e lançar. Use ao dizer "vamos trabalhar no PR N", ao revisar contribuição de terceiro, ou ao retomar um ramo parado.
---

# Trabalhar num PR

Esta skill é a **espinha**: ela diz *quando* cada coisa entra e *por quê*. O *como*
está nas skills apontadas, e não se repete aqui — passo que cabe numa frase mais um
ponteiro é uma frase mais um ponteiro.

**Nem todo PR termina em release.** As saídas legítimas estão no passo 6; a linha
reta até o lançamento é uma delas, não a única.

## Onde cada sinal leva

| O que aparece no diff ou no ramo | Skill que entra |
|---|---|
| `Gemfile` / `Gemfile.lock` | `dependencias` |
| SQL, unicidade, ordenação, migration | `suite-mariadb` |
| Asset, tela, PDF, planilha, e-mail | `homologacao` |
| Ramo atrás da `main` | `merge-downstream` |
| Qualquer mudança que precise ser medida | `safe-refactor` |
| Tudo verde e homologado | `release` |

## 1. Reconhecimento

```bash
gh pr view <N> --json title,state,headRefName,mergeable,commits,statusCheckRollup
git fetch --all --prune
git log --oneline main..origin/<ramo>      # o que o PR traz
git log --oneline origin/<ramo>..main      # o que falta da main entrar
```

A segunda lista vazia é o que se quer: a `main` já está dentro do ramo. Se não
estiver, `merge-downstream` antes de qualquer medida — medir contra base
desatualizada mede a defasagem, não o PR.

**Leia a issue e os comentários dela, não só o título.** É neles que está a
decisão de produto já tomada, a tentativa revertida e o que já foi homologado em
etapas anteriores. Vale para as issues relacionadas e fechadas também
(`gh issue list --state all --search`, `git log --all --grep`). Sem isso é fácil
tratar como novo um trecho que já foi validado, ou refazer discussão encerrada.

## 2. Diga que tipo de PR é este, antes de medir

Correção, feature ou upgrade — a classificação define o que conta como resultado,
e a `safe-refactor` traz os três critérios. O que esta skill exige é **declarar
qual é antes de rodar**: sem a lista de diferenças esperadas feita de antemão, é
fácil olhar para uma diferença inesperada e racionalizá-la como intencional.

## 3. Ler o diff — e, em upgrade, o diff certo

O diff do PR mostra o que o autor escreveu. Quando o PR mexe no `Gemfile`, o que
decide a revisão é o que mudou **na dependência**, e aí valem as notas do passo 1
da `safe-refactor`: procurar a página de migração da lib quando ela existir, notas
de versão depois, busca dirigida no código em seguida.

Duas coisas que só aparecem em revisão de upgrade:

- **As duas versões da gem convivem no disco** (`~/.rvm/gems/*/gems/<gem>-<versão>/`).
  Comparar o fonte das duas é mais barato e mais confiável do que deduzir do
  changelog: entrada que anuncia "adicionamos X" pode ser lógica que apenas
  **mudou de lugar**, sem efeito nenhum na tela.
- **Confira o que o autor precisou ajustar contra o guia da lib.** Instrução de
  migração costuma vir em prosa no changelog — "tal gem deixou de ser puxada e
  precisa ser declarada" — e é o tipo de item que passa despercebido e só quebra
  no deploy.

## 4. Prove que o caminho é alcançável aqui

Antes de escrever teste ou sonda para uma correção que veio de fora, confirme que
o código dela executa neste sistema: procure a chamada, a configuração que a liga,
a condição que a guarda. Busca vazia não basta — confirme que o padrão existe em
algum lugar do projeto.

**Instrumento para caminho inalcançável devolve "sem diferença", e isso se lê como
"não regrediu".** É pior do que não medir: consome tempo e produz falsa garantia.
Correção que não alcança este sistema entra no relatório como tal, sem sonda.

## 5. Lacunas de teste e de sonda

O que a mudança toca e a suíte não executa vira teste — pela `safe-refactor`,
inclusive a checagem de que o teste não é vazio. O que nem a suíte alcança vira
sonda, pela `homologacao`.

Revisão inverte a ordem da `safe-refactor`: a mudança **já existe**, então não dá
para escrever o teste contra o código velho. A saída é escrever contra o
comportamento novo e provar o vermelho **simulando a versão anterior** — com o
código dela, nunca com uma aproximação escrita à mão.

## 6. Nós ajustamos, ou volta para o autor?

É a decisão central da skill, e ela tem três saídas.

**Ajustamos nós, e seguimos** quando o PR está majoritariamente adequado: os
consertos do autor atacam a causa, o que falta é **aditivo** (teste que ninguém
escreveu, cobertura de um caminho novo) e não há decisão de produto em disputa.
Comentar no PR nesse caso só adia por dias um trabalho que já está pronto na
árvore.

**Comenta no PR e devolve** quando há retrabalho: a correção trata o sintoma no
lugar da causa, o número de ajustes reescreveria os commits do autor, ou falta
contexto que só ele tem.

**Para e pergunta ao mantenedor** quando a dúvida é de produto, não de código.

Duas coisas que **não** justificam devolver, e viram registro escrito: desvio de
convenção de mensagem de commit, e achado adjacente fora do escopo do PR — este
vira issue própria (pesquise as existentes antes, inclusive fechadas).

## 7. Medir

Suíte completa pela `safe-refactor`, com a contagem de exemplos comparada à
baseline — verde com menos exemplos é teste que sumiu. Confira também o CI na
ponta do ramo: ele roda o que a máquina local não roda, e roda em MariaDB — é a
medida que alcança os pontos cegos que o `AGENTS.md` lista. A contagem dele é
maior que a local; compare-a com a do CI na baseline, não com a sua.

**`gh pr checks <N>` sai com código não-zero enquanto há check pendente** (e
também quando algum falha), então tratar saída não-zero como erro transitório a
engolir faz o laço de espera girar calado, e o silêncio fica indistinguível de
"ainda rodando". Pendente *é* o estado, não uma falha ao consultá-lo: decida pelo
texto da saída, nunca pelo código de retorno.

`suite-mariadb` quando o diff toca SQL, unicidade, ordenação ou migration; verde
em SQLite não diz nada sobre esses pontos.

## 8. Homologar

`homologacao`, quando a mudança toca o que a suíte estruturalmente não alcança —
adaptador de banco, geração de PDF e planilha, renderização de tela, pipeline de
assets, e-mail. Ela inclui a passada de escrita nos dois lados: a comparação
sozinha é toda de leitura.

## 9. Lançar

`release`. Antes de chamá-la, isto tem de ser verdade: suíte completa verde no
ramo, homologação feita quando cabia, `main` sincronizada, árvore de trabalho
limpa e CI verde na ponta.

## 10. Fechar o rastro

Ao fim, cada aprendizado tem um lugar, e o critério está no `AGENTS.md`:

- **Comentário na issue** — medida de antes e depois, versão em que o defeito
  aparecia, armadilha que custou tempo. Fica junto do trabalho que o originou.
- **Linha de skill** — só o que faria uma rodada futura agir diferente.
- **Nada** — o resto. O `git log` já guarda.

E duas obrigações antes de considerar o PR encerrado:

- **Conclusão sua que caiu por evidência nova se corrige onde foi escrita.** Se
  virou mensagem de commit ainda não empurrada, reescreva o commit: o teste pode
  sobreviver com outro enquadramento, a justificativa errada não pode virar
  história.
- **Confronte medida com o campo quando as duas discordam.** A versão no ar
  (cabeçalho, antes da autenticação), o valor real no banco, uma tela de produção:
  são checagens baratas, e o campo ganha da dedução.
