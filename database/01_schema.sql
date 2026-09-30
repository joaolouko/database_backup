-- 01_schema.sql
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pedidos (
    id SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    valor DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE manutencao_log (
    id SERIAL PRIMARY KEY,
    database VARCHAR(255) NOT NULL,
    tipo_manutencao VARCHAR(50) NOT NULL,
    origem_decisao VARCHAR(50) NOT NULL,
    regra_aplicada VARCHAR(100) NOT NULL,
    inicio TIMESTAMP NOT NULL,
    fim TIMESTAMP NOT NULL,
    resultado VARCHAR(50) NOT NULL,
    mensagem_erro TEXT
);
