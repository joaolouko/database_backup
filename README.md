# Plataforma de Gerenciamento de Backup (PostgreSQL)

Trabalho prático desenvolvido para gerenciar backups de bancos de dados PostgreSQL, incluindo rotinas de manutenção, criptografia, compactação e histórico de execução, cumprindo os requisitos acadêmicos estipulados.

## 🛠 Ambientes e Requisitos

Este projeto foi construído e validado utilizando as versões obrigatórias estabelecidas para a entrega:
- **FVM**: 3.2.1
- **Flutter**: 3.38.7
- **Dart**: 3.10.7

## ✨ Funcionalidades Principais

- **Descoberta e Seleção**: Conexão com banco PostgreSQL (via `postgres_service`), permitindo seleção de banco alvo.
- **Testes de Conexão**: Validação de credenciais de forma independente, sem acionar backups.
- **Manutenção Automática**: Decisões baseadas em histórico usando SQLite local:
  - `< 30 dias`: Nenhuma ação
  - `30 a 60 dias`: VACUUM
  - `> 60 dias` ou sem histórico: VACUUM FULL ANALYZE
- **pg_dump e pg_restore**: Descoberta automática de executáveis nas pastas do PostgreSQL e orquestração controlada via `Process.start`
- **Criptografia AES**: Implementação real AES-256-GCM para proteger os backups.
- **Compressão ZIP**: Arquivos `dump/aes` encapsulados num ZIP funcional, pronto para extração e uso.
- **Retenção e Cópia**: O sistema apaga backups mais antigos limitados a um número X e gera uma cópia do backup em pasta separada configurada.
- **Restauro com Verificação**: Funcionalidade completa para descriptografar, descompactar e injetar via `pg_restore`, concluindo com verificação de integridade (análise de volume).
- **Simulação de E-mail**: Notificações demonstrativas na UI para casos de falha.
- **Auditoria, Segurança e Isolamento UI**: Processamentos pesados operam assincronamente (evitando UI blocks), senhas de DB são preservadas (se local) em instâncias seguras (`flutter_secure_storage`).

## 🗄️ Estrutura do Banco de Demonstração

Para demonstrar a eficácia e validar cenários na apresentação:
Scripts inclusos em `database/`
- `01_schema.sql`: Definição e relações base.
- `02_seed.sql`: Carga real mínima demonstrável.
- `03_mass_data.sql`: Massa considerável de teste para `pg_dump`
- `scenarios/scenarios.sql`: Casos controlados simulando a data de última manutenção

## 🚀 Instalação e Execução

1. Garanta o FVM instalado (`fvm --version` para validar 3.2.1)
2. Garanta a SDK do Flutter correspondente: `fvm install 3.38.7` e `fvm use 3.38.7`.
3. Rode `fvm flutter pub get`
4. Crie no PostgreSQL uma base e importe os scripts em `database/` (Ex: via PgAdmin ou psql).
5. Execute a aplicação: `fvm flutter run -d windows`

## Cenários de Demonstração (Matriz de Testes)

Conforme a avaliação do trabalho, as validações cobrem:
1. **Sem histórico**: Restaura o modelo, aciona VACUUM FULL ANALYZE.
2. **<30 dias**: Ignora rotinas, segue o pipe direto.
3. **30–60 dias**: Aciona VACUUM standard.
4. **>60 dias**: Aciona VACUUM FULL ANALYZE.
5. **Manutenção manual**: Overrides automáticos, roda a completa ou nula.
6. **Backup simples**: Roda limpo, verifica saída *.dump.
7. **Backup criptografado**: Roda e lança output criptografado AES.
8. **Backup compactado**: Roda compressão funcional via archive.
9. **Criptografia + compactação**: Pipeline completo preservando a ordem (Dump > AES > ZIP).
10. **Retenção**: Define N=2, gera o 3º, e valida exclusão do 1º gerado.
11. **Cópia adicional**: Gera arquivo extra no caminho adicional.
12. **Falha**: Força credenciais inválidas, valida tratamento sem crash, com popup e envio de log falso.
13. **Log**: Navega no "Histórico" validando a riqueza da auditoria salva no SQLite.
14. **Email simulado**: Engatilhado em decorrência do caso 12.
15. **Restauração e Integridade**: Seleciona o backup final, preenche os passwords de AES e ZIP, submete. Sistema recupera a dump e re-popula a base, exibindo volume do database validando integridade.

## 📁 Arquitetura do Software Refatorada
- `main.dart` atua apenas como entry-point e injeta localizadores de serviço
- `lib/app` e `lib/core`: Bootstraping, temas e configurações em singleton e local db.
- `lib/models` : Domínios
- `lib/services`: Controladores agnósticos orquestradores (PostgresService, BackupService).
- `lib/screens`: Separação baseada por View.
