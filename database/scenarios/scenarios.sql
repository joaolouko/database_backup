-- sem_historico.sql
-- Nao insere nada na tabela manutencao_log, simulando banco novo ou sem historico

-- menos_30_dias.sql
INSERT INTO manutencao_log (database, tipo_manutencao, origem_decisao, regra_aplicada, inicio, fim, resultado)
VALUES ('postgres', 'VACUUM FULL ANALYZE', 'Manual', 'Manual', NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days', 'SUCESSO');

-- entre_30_60_dias.sql
INSERT INTO manutencao_log (database, tipo_manutencao, origem_decisao, regra_aplicada, inicio, fim, resultado)
VALUES ('postgres', 'VACUUM', 'Automática', 'Automática baseada no histórico', NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days', 'SUCESSO');

-- mais_60_dias.sql
INSERT INTO manutencao_log (database, tipo_manutencao, origem_decisao, regra_aplicada, inicio, fim, resultado)
VALUES ('postgres', 'VACUUM FULL ANALYZE', 'Automática', 'Automática baseada no histórico', NOW() - INTERVAL '70 days', NOW() - INTERVAL '70 days', 'SUCESSO');
