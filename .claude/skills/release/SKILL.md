---
name: release
description: Lança uma nova versão do SAPOS — merge na main, tag anotada, label e issues no GitHub, release publicada. Use quando um ramo estiver homologado e pronto para virar versão, ou quando precisar conferir como as releases anteriores foram feitas.
---

# Release do SAPOS

Sequência para transformar um ramo pronto em versão publicada. O passo final —
o deploy em produção — **é do mantenedor**; a skill vai até a release no GitHub.

## Pré-requisitos

Não comece sem isto:

- Suíte completa verde no ramo (`bundle exec rspec`, ~12 min).
- Homologação feita, quando a mudança toca o que a suíte não alcança (skill
  `homologacao`).
- Passada manual do mantenedor em staging, quando houver caminho de escrita, PDF,
  planilha ou e-mail envolvido — a captura automatizada é só leitura.
- `main` sincronizada com `origin/main`: `git rev-list --left-right --count origin/main...main` → `0 0`.
- **Árvore de trabalho limpa: `git status --short` vazio.** Se houver qualquer
  coisa não commitada, **pare e avise o mantenedor antes do merge** — mostrando o
  quê, e perguntando se entra nesta versão ou fica para a próxima. A decisão é
  dele; o que não pode é ele descobrir depois da release publicada, quando entrar
  já custa outra versão.

  Isso vale inclusive para o que o próprio agente escreveu durante o ciclo:
  anotação em skill, roteiro, script de sonda. Ter avisado no meio do caminho, ao
  criar o arquivo, **não conta** — o aviso tem que estar aqui, junto da decisão
  de lançar. Foi assim que a anotação da skill `homologacao` ficou de fora da
  7.15.27.

## Passos

### 1. Levante o que sai na release

```bash
git log --oneline <tag_anterior>..<ramo>
git log <tag_anterior>..<ramo> --format='%h %s%n%b' | grep -iE '#[0-9]+' | sort -u
```

Separe as issues **atendidas** das apenas **citadas**. Um commit que diz "isso
fica para issue própria (#626)" não atende a #626 — mencionar não é entregar.

Trabalho de vulnerabilidade **não tem issue** (ver `AGENTS.md`): vai aparecer
como commits sem referência. Isso é esperado, e o passo 6 diz como descrevê-lo.

### 2. O número da versão

Quem define é o mantenedor. Se ele não informar, proponha o incremento de patch
sobre a última tag (`git tag -l --sort=-v:refname | head -3`; `7.15.20` → `7.15.21`)
e **peça confirmação antes de criar a tag** — o incremento pode não ser de patch.

### 3. Merge na main, fast-forward

```bash
git checkout main
git merge --ff-only <ramo>
git push origin main
```

O `--ff-only` é proposital: pelo modelo de ramos (`CONTRIBUTING.md`), o ramo
já mergeou a `main` nele antes do PR, então o merge **tem** que ser
fast-forward. Se o git recusar, não force nem faça merge commit — o ramo está
desatualizado e precisa integrar a `main` primeiro, com a suíte rodada de novo.

Nem toda release passa por PR; quando o mantenedor dispensa, o merge é direto.

### 4. Tag anotada

```bash
git tag -a 7.15.21 -m "7.15.21"
git push origin 7.15.21
```

Sempre anotada (`-a`), nunca leve. As tags antigas têm mensagem vazia e a
`7.15.19` tem o próprio número; use o número.

A tag não é decorativa: `config/environment.rb:12` deriva `APP_VERSION` de
`git describe --tag --always` em tempo de execução, então é ela que aparece no
rodapé da aplicação.

### 5. Label e issues

```bash
gh label create 7.15.21 --color 0e8a16 --repo gems-uff/sapos
gh issue edit <N> --add-label 7.15.21
gh issue close <N> --reason completed
```

- Cor `0e8a16` para todo label de versão — é o que dá o verde uniforme na lista.
- **Rotular e fechar são decisões separadas.** Uma issue entregue em parte leva o
  label e continua aberta (a #621 tem `7.15.19` e segue aberta). Só feche o que
  a versão de fato encerra.
- Fechamento é `completed`, sem comentário de encerramento — é o padrão do
  repositório.

### 6. Release no GitHub

```bash
gh api repos/gems-uff/sapos/releases \
  -f tag_name=7.15.21 \
  -f name='' \
  -f body='Issues atendidas: https://github.com/gems-uff/sapos/issues?q=label%3A7.15.21' \
  -F draft=false -F prerelease=false
```

O nome é **vazio** — o GitHub exibe a tag. Por isso a chamada é pela API: o
`gh release create` quer título.

O corpo aponta para a consulta do label, e não para uma lista escrita à mão, que
envelhece. Repare no `%3A` — é o `:` de `label:7.15.21` codificado.

**Quando a versão traz trabalho sem issue** (o caso das vulnerabilidades),
descreva em prosa antes do link e troque o rótulo dele:

```
Atualização do Rails de 7.1.6 para 7.2.3.1.

Demais issues atendidas: https://github.com/gems-uff/sapos/issues?q=label%3A7.15.21
```

Sem isso, a release diz "issues atendidas" sobre uma versão cuja mudança
principal não está em issue nenhuma. Para vulnerabilidade, descreva a
atualização (gem, de → para) **sem citar CVE nem descrever o ataque**.

### 7. Confira

```bash
gh release list --limit 3          # a nova deve aparecer como Latest
gh issue list --label 7.15.21 --state all
```

### 8. Deploy — do mantenedor

**Passe a tag certa.** Uma versão errada exibida em produção já foi rastreada
até a tag passada no deploy, não ao Passenger. Depois de subir, confira o rodapé
da aplicação.

## Depois da release

- Apague o ramo lançado (GitHub e local), e pode `git fetch --prune`.
- Se a release fecha alerta do Dependabot, ele só re-varre o ramo padrão — o
  quadro de alertas leva alguns minutos para refletir o push.
