---
name: provar-candidato
description: Transforma suspeita de defeito em achado confirmado, refutado ou declaradamente plausível — reprodução com controle e um veredito por afirmação. Use ao triar saída de code review, ao investigar bug relatado, ou antes de afirmar num PR ou numa issue que alguma coisa está quebrada.
---

# Provar um candidato

Suspeita não é achado. Candidato que vai ao autor sem prova gasta o tempo dele e
a sua credibilidade; candidato descartado sem prova deixa um defeito no ar. Os
dois erros se evitam do mesmo jeito.

## A escalada, do mais barato para o mais caro

1. **Um comando.** Para cada candidato, pergunte se um `grep` ou um `rails runner`
   fecha o caso. A maioria fecha, e é aqui que o trabalho acontece.
2. **Um agente**, quando o comando não fechou. O que ele compra é contexto
   descartável para a iteração — montar cenário, autenticar papel, ler fonte de
   gem —, que no seu contexto ficaria para sempre. **Um basta:** o que separa
   achado de falso positivo é a prova com controle, não a quantidade de opiniões
   sobre o mesmo trecho.

## Os três vereditos

- **Confirmado** — reprodução que falha na árvore atual.
- **Plausível** — o mecanismo é real e você não confirmou. Diga **o que
  confirmaria**: é esse campo que roteia o candidato para um teste, para a
  `suite-mariadb`, para a `homologacao` ou para uma pergunta ao mantenedor.
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

## Regras da prova

- **Prova sem controle não prova.** Mostre que o cenário sem o defeito se comporta
  de outro jeito, e pergunte: este script falharia igual se o defeito não
  existisse?
- **Confirme que o caminho é alcançável neste sistema** — sobretudo em correção
  que veio de fora. Procure a chamada, a configuração que a liga, a condição que a
  guarda. Valem aqui as duas armadilhas do passo 1 da `safe-refactor` — busca
  vazia não é evidência; execute em vez de deduzir —, que não são só de upgrade. **Instrumento para caminho
  inalcançável devolve "sem diferença", e isso se lê como "não regrediu"**: pior
  que não medir, porque consome tempo e produz falsa garantia. Correção que não
  alcança este sistema é refutada, e entra no relatório como tal — sem teste e sem
  sonda.
- **Afirmação de consequência exige varredura executada, não lida.** Rode cada
  consumidor com os dois valores. Os que escapam a quem só lê: exportação,
  template Liquid — e o que o drop expõe, que pode não incluir o método —,
  consulta gravada em SQL, e `.nil?` ou `||` sobre o retorno.
- **Não envolva a reprodução em transação quando o que está sob teste envolve
  transação.** Bloco aninhado não cria savepoint, engole o rollback interno, e
  você mede o oposto do que o código faz. Limpe por truncation, ou meça sem
  envelope.
- **Duas reproduções que se contradizem: rode as duas antes de discutir.** Em
  geral uma falha o próprio controle, ou as duas medem cenários diferentes.
  Discussão é o instrumento de quando não se pode rodar o experimento — aqui se
  pode.
- **Confronte medida com o campo quando as duas discordam.** A versão no ar
  (cabeçalho, antes da autenticação), o valor real no banco, uma tela de produção:
  são checagens baratas, e o campo ganha da dedução.
- **Candidato que só se sustenta por defeito de outro arquivo vira item próprio.**
  Não use defeito alheio para escorar o que está em pauta.

## Armadilhas ao montar o cenário neste projeto

- **Achado de permissão se prova por requisição, não por modelo**, porque o
  `current_user` só existe dentro de uma (ver "Pontos cegos da suíte" no
  `AGENTS.md`). Request spec em `spec/requests/`, com **dois controles** — que a
  tela não oferece o campo (o usuário não deveria poder) e que alterar uma
  **coluna** pelo mesmo caminho é barrado (a validação está viva, então "passou"
  não é porque o mecanismo morreu). Sem os dois, o vermelho não distingue defeito
  de cenário mal montado.
- **Um usuário tem um papel ativo por vez** (`Ability`, `roles = { actual_role =>
  true }`), e atribuir papel depois de criar o usuário deixa `actual_role` no valor
  antigo. Permissão que não aparece costuma ser isso, e não caminho inalcançável —
  confira antes de concluir que o candidato é impossível.

## O que sai daqui

Um item por candidato, no mesmo formato sirva ele ao relatório da revisão, ao
comentário no PR ou à issue: **o veredito**; **como se provou** — o comando ou a
spec, e o controle que a acompanha; e, só nos plausíveis, **o que confirmaria** e
para onde isso manda o candidato.

Refutado entra no relatório igual ao confirmado: quem levantou o candidato precisa
saber que ele caiu, e por quê. E reprodução de confirmado não se joga fora — vai
limpa, com nome e lugar de spec do projeto, sem resquício do script exploratório
que a gerou, e é ela que viaja ao autor ou vira a cobertura do conserto.
