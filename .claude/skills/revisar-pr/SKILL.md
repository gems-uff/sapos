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

Dispare também `/code-review xhigh <N>` — ele roda em background pelo tempo dos
passos 1 a 3, e o número do PR lhe dá os comentários do autor, que são contexto.
Ele lê os arquivos do checkout, então precisa do ramo em disco.

- **`xhigh`, não menos.** Níveis abaixo podem cair numa variante de passada
  única, com menos ângulos e sem a varredura final de lacunas.
- **Nunca `--comment` nem `--fix`.** O primeiro publica no PR; o segundo aplica
  na árvore fora dos checkpoints, e `/rewind` não desfaz.
- **Não há verificação e há piso de achados.** O que ele devolve é candidato, não
  achado — quem tria é o passo 4; o fim da lista costuma ser o piso, não descoberta.

Ele pega o que escapa da leitura linear: argumento em posição errada, `includes`
que não preenche a associação que a view lê, objeto gravado no banco que a
migration não acompanha. Não alcança o que depende de produção nem cobra
homologação — isso continua nos passos 5 e 8.

## 2. Diga que tipo de PR é este, antes de medir

Correção, feature ou upgrade — a classificação define o que conta como resultado,
e a `safe-refactor` traz os três critérios. O que esta skill exige é **declarar
qual é antes de rodar**: sem a lista de diferenças esperadas feita de antemão, é
fácil olhar para uma diferença inesperada e racionalizá-la como intencional.

## 3. Ler o diff — e, em upgrade, o diff certo

**Leia o diff você mesmo, e anote os seus candidatos** — não delegue isto ao
`/code-review`. A leitura mecânica é boa no que se decide dentro do arquivo:
argumento em posição errada, `includes` que não preenche a associação lida, guarda
que virou inerte. Quatro classes de candidato **só saem da sua leitura**, porque
dependem de coisas que não estão no repositório:

- **O efeito nas instalações reais** — quantas consultas gravadas param de casar
  com o esquema, quantas notificações dependem delas, quais têm disparo agendado.
  É `rake queries:check` nas instalações, e é o achado de maior peso que uma
  revisão produz.
- **A cobertura que a issue pede**, e não a que existe. Máquina reclama de teste
  ausente como nit, quando ausente; ela não sabe o que a issue prometeu.
- **O que o merge vai encontrar** — o que a `main` andou, qual spec dela deixa de
  compilar contra a modelagem nova, onde o conflito real vai cair.
- **Decisão de produto** — se a mudança de cardinalidade de um relatório está
  certa, se o pedido que você mesmo fez ao autor era razoável. Isso não é achado,
  é julgamento, e retratar-se em público é parte do trabalho.

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

## 4. Triar os candidatos

O que sai do `/code-review` e da sua leitura são **candidatos**, não achados.
Candidato que vai ao autor sem prova gasta o tempo dele e a sua credibilidade;
candidato descartado sem prova deixa um defeito no ar. Os dois erros se evitam do
mesmo jeito, e a ordem abaixo é o que faz a triagem sair barata:

1. **Um comando.** Para cada candidato, pergunte se um `grep` ou um `rails runner`
   fecha o caso. A maioria fecha, e é aqui que o trabalho acontece.
2. **Um agente**, quando a tentativa acima não fechou. O que ele compra é contexto
   descartável para a iteração — montar cenário, autenticar papel, ler fonte de
   gem —, que no seu contexto ficaria para sempre. **Um basta:** o que separa
   achado de falso positivo é a prova com controle, não a quantidade de opiniões
   sobre o mesmo trecho.
3. **Duas reproduções que se contradizem:** rode as duas antes de discutir. Em
   geral uma falha o próprio controle, ou as duas medem cenários diferentes.
   Discussão é o instrumento de quando não se pode rodar o experimento — aqui se
   pode.

### Os três vereditos

- **Confirmado** — reprodução que falha na árvore atual.
- **Plausível** — o mecanismo é real e você não confirmou. Diga **o que
  confirmaria**: é esse campo que roteia o candidato para o teste do passo 5, para
  a `suite-mariadb`, para a `homologacao` ou para uma pergunta ao mantenedor.
- **Refutado** — a linha que torna o defeito impossível, ou reprodução mostrando
  que a falha alegada não ocorre.

**Plausível é dial de confiança, não de gravidade.** Se você confirmou tudo que
era checável, o veredito não é plausível ainda que o defeito seja pequeno —
gravidade se diz na prosa. Rebaixar por gravidade faz o leitor reabrir verificação
já encerrada.

**Um veredito por afirmação.** Candidato que empacota mecanismo, gatilho e
consequência precisa de veredito em cada um: "mecanismo sim, gatilho não,
consequência sim por outra porta" é resposta frequente e legítima. Rótulo único
para o conjunto esconde qual parte o autor tem de consertar.

### Regras da prova

- **Prova sem controle não prova.** Mostre que o cenário sem o defeito se comporta
  de outro jeito, e pergunte: este script falharia igual se o defeito não
  existisse?
- **Confirme que o caminho é alcançável neste sistema** — sobretudo em correção
  que veio de fora. Procure a chamada, a configuração que a liga, a condição que a
  guarda; busca vazia não basta, confirme que o padrão existe em algum lugar do
  projeto. **Instrumento para caminho inalcançável devolve "sem diferença", e isso
  se lê como "não regrediu"**: pior que não medir, porque consome tempo e produz
  falsa garantia. Correção que não alcança este sistema é refutada, e entra no
  relatório como tal — sem teste e sem sonda.
- **Afirmação de consequência exige varredura executada, não lida.** Rode cada
  consumidor com os dois valores. Os que escapam a quem só lê: exportação,
  template Liquid — e o que o drop expõe, que pode não incluir o método —,
  consulta gravada em SQL, e `.nil?` ou `||` sobre o retorno.
- **Não envolva a reprodução em transação quando o que está sob teste envolve
  transação.** Bloco aninhado não cria savepoint, engole o rollback interno, e
  você mede o oposto do que o código faz. Limpe por truncation, ou meça sem
  envelope.
- **O "antes" se mede no merge-base, não na `main`** — ramo atrasado mediria o PR
  somado ao que a `main` andou. Worktree em `git merge-base origin/main HEAD`,
  `cp config/database.yml.example config/database.yml` (o real não é versionado, e
  sem ele o ambiente não sobe) e `rake db:schema:load`. É também como se descobre
  que **um candidato já valia antes do PR**: não é regressão, e a mensagem ao autor
  muda de "você quebrou" para "isto piorou aqui, conserta agora ou vira issue?".
- **Achado de permissão se prova por requisição, não por modelo:** o
  `current_user` vem do active_scaffold e é nil fora de uma. Request spec em
  `spec/requests/`, com **dois controles** — que a tela não oferece o campo (o
  usuário não deveria poder) e que alterar uma **coluna** pelo mesmo caminho é
  barrado (a validação está viva, então "passou" não é porque o mecanismo morreu).
  Sem os dois, o vermelho não distingue defeito de cenário mal montado.
- **Um usuário tem um papel ativo por vez** (`Ability`, `roles = { actual_role =>
  true }`), e atribuir papel depois de criar o usuário deixa `actual_role` no valor
  antigo. Permissão que não aparece costuma ser isso, e não caminho inalcançável —
  confira antes de concluir que o candidato é impossível.
- **Candidato que só se sustenta por defeito de outro arquivo vira item próprio.**
  Não use defeito alheio para escorar o que está em pauta.

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

**Ao devolver, mande os testes junto — não só a prosa.** As reproduções do passo 4
já afirmam o comportamento correto e falham enquanto o defeito existir, então
commitá-las no ramo do autor deixa a suíte dele vermelha até o conserto. Isso é
mais útil que descrição, e não é acusação: o teste **é a especificação do
conserto**, e vale dizer isso no comentário. Empurrar em ramo de terceiro é
decisão do mantenedor — deixe pronto e peça.

Duas condições. O teste vai limpo, com nome e lugar de spec do projeto, sem
resquício do script exploratório que o gerou. E **feedback em uma rodada**: junte
tudo — confirmados, refutados, o que não é regressão e o que ficou em aberto —
em vez de comentar achado a achado, que faz o autor perseguir alvo móvel.

**Vulnerabilidade introduzida pelo próprio PR pode ser discutida nele**, porque
não há sistema no ar exposto: o defeito nasce no merge. Já vulnerabilidade
**pré-existente**, achada de passagem, a gente corrige de imediato e sem issue
pública — é a regra do `AGENTS.md`, e enumerar o ataque antes da correção é o que
ela evita.

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
