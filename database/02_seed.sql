-- 02_seed.sql
INSERT INTO usuarios (nome, email) VALUES 
('João Silva', 'joao@example.com'),
('Maria Santos', 'maria@example.com'),
('Carlos Pereira', 'carlos@example.com');

INSERT INTO pedidos (usuario_id, valor, status) VALUES 
(1, 150.00, 'CONCLUIDO'),
(2, 299.90, 'PENDENTE'),
(3, 49.50, 'CANCELADO');
