---
name: suite-mariadb
description: Sobe um MariaDB local fiel ao de produção e roda a suíte contra ele, em vez do SQLite. Use ao mexer em consulta SQL, validação de unicidade, ordenação, migration ou qualquer coisa cujo comportamento dependa do banco.
---

# Suíte contra MariaDB local

A suíte roda em **SQLite**; produção roda em **MariaDB**. Não é só diferença de
conexão — a semântica muda:

- A collation de produção é *case-insensitive* **e** *accent-insensitive*. Num
  sistema em português isso altera validação de unicidade, `ORDER BY` e `LIKE`.
  "José" e "jose" são o mesmo valor lá, e valores distintos no SQLite.
- `STRICT_TRANS_TABLES` rejeita o que o SQLite aceita calado (string maior que a
  coluna, tipo incompatível).
- DDL não é transacional no MariaDB.
- `Query.run_read_only_query` tem um ramo `Mysql2` que o SQLite nunca executa.

Esta skill monta um ambiente **fiel** e roda a suíte inteira nele. Complementa a
skill `homologacao`: lá se exercita uso real com dado real; aqui se exercita as
**asserções do projeto** sob a semântica do banco de verdade, e o resultado vai
para o CI.

## Descubra a configuração real antes de montar

Não presuma. Rode no servidor e copie os valores:

```sql
SELECT @@version, @@sql_mode;
SELECT DEFAULT_COLLATION_NAME FROM information_schema.SCHEMATA
  WHERE SCHEMA_NAME = DATABASE();
SELECT DISTINCT TABLE_COLLATION FROM information_schema.TABLES
  WHERE TABLE_SCHEMA = DATABASE();
```

**A collation que vale é a materializada nas tabelas, não a declarada no
`config/database.yml`.** No SAPOS elas divergem: o arquivo declara
`utf8mb4_unicode_520_ci` e as tabelas usam `utf8mb4_unicode_ci`. A chave do
arquivo só age no `db:create`, então seguir o arquivo produz um ambiente que
diverge de produção exatamente na dimensão que se quer medir — e as falhas de
collation resultantes pareceriam diferença SQLite/MariaDB, quando seriam
artefato do setup.

Case igualmente a versão: instale a mesma série do servidor, não a mais recente.

## Montagem

Instância **efêmera**, com diretório e porta próprios. Nada de `brew services`:
não há motivo para um banco de teste subir no login da máquina.

```bash
M=/opt/homebrew/opt/mariadb@10.5      # a série do servidor
D=$HOME/sapos-mariadb-test

brew install mariadb@10.5
mkdir -p $D/data
$M/bin/mysql_install_db --datadir=$D/data --basedir=$M \
  --auth-root-authentication-method=normal

$M/bin/mysqld_safe --datadir=$D/data --basedir=$M \
  --port=3307 --socket=$D/mysql.sock --pid-file=$D/mysql.pid \
  --bind-address=127.0.0.1 \
  --sql-mode="STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" \
  --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci \
  > $D/mysqld.log 2>&1 &

$M/bin/mysql --socket=$D/mysql.sock -u root \
  -e "CREATE DATABASE sapos_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

A gem `mysql2` está no grupo `production` do Gemfile e o `.bundle/config` local
costuma trazer `BUNDLE_WITHOUT: production`, então ela nem chega a ser instalada:

```bash
bundle config set --local without ''
bundle install
```

`.bundle` é gitignored, então isso não vaza para o repositório.

## Execução

**Não edite `config/database.yml`** — ele é versionado e aponta o teste para
SQLite de propósito. Use `DATABASE_URL`, que o Rails sobrepõe:

```bash
export DATABASE_URL="mysql2://root@127.0.0.1:3307/sapos_test?encoding=utf8mb4&collation=utf8mb4_unicode_ci"

RAILS_ENV=test bundle exec rails db:schema:load
SKIP_COVERAGE=1 bundle exec rspec
```

Confira que o ambiente ficou fiel antes de confiar no resultado — número de
tabelas e collation única devem bater com produção:

```sql
SELECT COUNT(*), COUNT(DISTINCT TABLE_COLLATION), MIN(TABLE_COLLATION)
  FROM information_schema.TABLES WHERE TABLE_SCHEMA='sapos_test';
```

## Como interpretar as falhas

Falha aqui **não é sinônimo de bug**. Há três categorias, e a diferença importa:

1. **Asserção que só vale no SQLite.** Exemplo típico: um spec afirmando
   unicidade *case-sensitive* quando a collation de produção é
   *case-insensitive*. O spec está errado, não o sistema — e, pior, ele afirma
   uma garantia que produção não oferece. Corrigir o spec **aumenta** a
   confiança.
2. **Bug real, que o SQLite escondia.** Tipicamente tipagem estrita ou dependência
   de ordenação. Vale issue.
3. **Artefato do setup.** Collation, `sql_mode` ou versão diferentes do servidor.
   Antes de concluir 1 ou 2, confirme que o ambiente está fiel.

Suspeite da categoria 3 primeiro: é a mais fácil de causar sem perceber e a que
produz o diagnóstico mais enganoso.

## Desmontagem

```bash
kill $(cat $HOME/sapos-mariadb-test/mysql.pid)
rm -rf $HOME/sapos-mariadb-test
bundle config set --local without production
```
