-- ============================================
-- 				Criando Database
-- ============================================
CREATE DATABASE IF NOT EXISTS gestao_estoque;
USE gestao_estoque;

-- ============================================
-- 				Criando Tables
-- ============================================
CREATE TABLE Responsavel (
  id_resp int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nome varchar(120) NOT NULL,
  email varchar(250) UNIQUE,
  telefone varchar(20),
  cargo varchar(40)
);

CREATE TABLE Sala (
  id_sala int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nome_sala varchar(80) NOT NULL,
  localizacao varchar(120),
  id_resp int UNSIGNED NOT NULL
);

CREATE TABLE Estoque (
  id_estoque int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  id_sala int UNSIGNED NOT NULL,
  nome varchar(80) NOT NULL,
  data_criacao date,
  status varchar(20) DEFAULT 'ATIVO'
);

CREATE TABLE Categoria_Produto (
  id_categoria int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nome_cat varchar(60) UNIQUE NOT NULL,
  sub_cat varchar(60),
  descricao_produto text
);

CREATE TABLE Produto (
  id_produto int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nome_produto varchar(120) NOT NULL,
  id_categoria int UNSIGNED NOT NULL,
  valor_unitario numeric(14,2) NOT NULL,
  unidade_medida varchar(15),
  ativo boolean NOT NULL DEFAULT true
);

CREATE TABLE Estoque_Produto (
  id_estoque int UNSIGNED NOT NULL,
  id_produto int UNSIGNED NOT NULL,
  quantidade_atual numeric(14,3) NOT NULL,
  quantidade_minima numeric(14,3) NOT NULL DEFAULT 0,
  PRIMARY KEY (id_estoque, id_produto)
);

CREATE TABLE Usuario (
  id_usuario int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nome varchar(120) NOT NULL,
  email varchar(250) UNIQUE,
  cargo ENUM ('ADMIN', 'OPERADOR')
);

CREATE TABLE Movimentacao (
  id_mov int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  id_estoque int UNSIGNED NOT NULL,
  id_produto int UNSIGNED NOT NULL,
  tipo ENUM ('ENTRADA', 'SAIDA', 'AJUSTE') NOT NULL,
  quantidade numeric(14,3) NOT NULL,
  data_mov timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  id_usuario int UNSIGNED,
  observacao text
);

CREATE TABLE Fornecedor (
  id_forn int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  razao_social varchar(160) NOT NULL,
  cnpj varchar(20) UNIQUE,
  telefone varchar(20),
  email varchar(255)
);

CREATE TABLE Pedido_Compra (
  id_pedido int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  id_forn int UNSIGNED NOT NULL,
  data_pedido date NOT NULL,
  status ENUM ('ABERTO', 'APROVADO', 'ENTREGUE') DEFAULT 'ABERTO',
  valor_total numeric(16,2) NOT NULL
);

CREATE TABLE Pedido_Produto (
  id_pedido int UNSIGNED NOT NULL,
  id_produto int UNSIGNED NOT NULL,
  quantidade numeric(14,3) NOT NULL,
  valor_unitario numeric(14,2) NOT NULL,
  PRIMARY KEY (id_pedido, id_produto)
);

CREATE TABLE Fornecedor_Produto (
  id_forn int UNSIGNED NOT NULL,
  id_produto int UNSIGNED NOT NULL,
  preco_custo numeric(14,2),
  codigo_produto_fornecedor varchar(50),
  PRIMARY KEY (id_forn, id_produto)
);

-- ============================================
-- 					INDEX
-- ============================================
CREATE INDEX Estoque_Produto_index_0 ON Estoque_Produto (id_produto);
CREATE INDEX Movimentacao_index_1 ON Movimentacao (id_estoque, id_produto, data_mov);
CREATE INDEX Movimentacao_index_2 ON Movimentacao (id_usuario);
CREATE INDEX Pedido_Compra_index_3 ON Pedido_Compra (id_forn);
CREATE INDEX Pedido_Produto_index_4 ON Pedido_Produto (id_produto);

-- ============================================
-- 				  Comentários
-- ============================================
ALTER TABLE Responsavel COMMENT = 'Quem gerencia uma ou mais Salas.';
ALTER TABLE Sala COMMENT = 'Ambiente físico que possui Estoques.';
ALTER TABLE Estoque COMMENT = 'Agrupa itens por sala/finalidade (status: ATIVO/INATIVO).';
ALTER TABLE Categoria_Produto COMMENT = 'Taxonomia para classificar Itens.';
ALTER TABLE Produto COMMENT = 'Recurso estocado/comprado (SKU).';
ALTER TABLE Estoque_Produto COMMENT = 'Relação N:N entre Estoque e Item + saldos.';
ALTER TABLE Usuario COMMENT = 'Usuário que executa movimentações (retirada/entrada/ajuste).';
ALTER TABLE Movimentacao COMMENT = 'Histórico de entradas, saídas e ajustes.';
ALTER TABLE Fornecedor COMMENT = 'Fornecedor de itens.';
ALTER TABLE Pedido_Compra COMMENT = 'Ordem de compra vinculada a um fornecedor.';
ALTER TABLE Pedido_Produto COMMENT = 'Itens que compõem cada pedido de compra.';
ALTER TABLE Fornecedor_Produto COMMENT = 'Tabela que define quais produtos cada fornecedor pode fornecer e a que custo.';

-- ============================================
-- 				Relacionamentos
-- ============================================
ALTER TABLE Sala ADD FOREIGN KEY (id_resp) REFERENCES Responsavel (id_resp);
ALTER TABLE Estoque ADD FOREIGN KEY (id_sala) REFERENCES Sala (id_sala);
ALTER TABLE Produto ADD FOREIGN KEY (id_categoria) REFERENCES Categoria_Produto (id_categoria);
ALTER TABLE Estoque_Produto ADD FOREIGN KEY (id_estoque) REFERENCES Estoque (id_estoque);
ALTER TABLE Estoque_Produto ADD FOREIGN KEY (id_produto) REFERENCES Produto (id_produto);
ALTER TABLE Movimentacao ADD FOREIGN KEY (id_estoque) REFERENCES Estoque (id_estoque);
ALTER TABLE Movimentacao ADD FOREIGN KEY (id_produto) REFERENCES Produto (id_produto);
ALTER TABLE Movimentacao ADD FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario);
ALTER TABLE Pedido_Compra ADD FOREIGN KEY (id_forn) REFERENCES Fornecedor (id_forn);
ALTER TABLE Pedido_Produto ADD FOREIGN KEY (id_pedido) REFERENCES Pedido_Compra (id_pedido);
ALTER TABLE Pedido_Produto ADD FOREIGN KEY (id_produto) REFERENCES Produto (id_produto);
ALTER TABLE Fornecedor_Produto ADD FOREIGN KEY (id_forn) REFERENCES Fornecedor(id_forn);
ALTER TABLE Fornecedor_Produto ADD FOREIGN KEY (id_produto) REFERENCES Produto(id_produto);

-- ============================================
-- 				Tabela de Log
-- ============================================
CREATE TABLE Log_Eventos (
  id_log int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  data_evento timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  tabela_afetada varchar(50) NOT NULL,
  id_registro_afetado int UNSIGNED,
  acao_realizada ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
  id_usuario_logado varchar(100),
  descricao text
) COMMENT = 'Registra eventos importantes no sistema para fins de auditoria.';

-- ============================================
-- 				Triggers
-- ============================================
DELIMITER $$
CREATE TRIGGER Att_estoque
AFTER INSERT ON Movimentacao
FOR EACH ROW
BEGIN
    IF NEW.tipo = 'ENTRADA' THEN
        UPDATE Estoque_Produto
        SET quantidade_atual = quantidade_atual + NEW.quantidade
        WHERE id_estoque = NEW.id_estoque AND id_produto = NEW.id_produto;
    ELSEIF NEW.tipo = 'SAIDA' THEN
        UPDATE Estoque_Produto
        SET quantidade_atual = quantidade_atual - NEW.quantidade
        WHERE id_estoque = NEW.id_estoque AND id_produto = NEW.id_produto;
    ELSEIF NEW.tipo = 'AJUSTE' THEN
        UPDATE Estoque_Produto
        SET quantidade_atual = NEW.quantidade
        WHERE id_estoque = NEW.id_estoque AND id_produto = NEW.id_produto;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER estoque_negativo
BEFORE INSERT ON Movimentacao
FOR EACH ROW
BEGIN
    DECLARE estoque_disponivel NUMERIC(14,3);

    IF NEW.tipo = 'SAIDA' THEN
        SELECT quantidade_atual INTO estoque_disponivel
        FROM Estoque_Produto
        WHERE id_estoque = NEW.id_estoque AND id_produto = NEW.id_produto;

        IF estoque_disponivel < NEW.quantidade THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Operação cancelada: Estoque insuficiente.';
        END IF;
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER safe_delete
BEFORE DELETE ON Produto
FOR EACH ROW
BEGIN
    DECLARE saldo_existente INT DEFAULT 0;

    SELECT 1 INTO saldo_existente
    FROM Estoque_Produto
    WHERE id_produto = OLD.id_produto AND quantidade_atual > 0
    LIMIT 1;

    IF saldo_existente = 1 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Operação cancelada: Não é possível excluir o produto, pois ele ainda possui saldo em estoque.';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER log_produto_update
AFTER UPDATE ON Produto
FOR EACH ROW
BEGIN
    DECLARE detalhes_log TEXT;
    
    IF OLD.nome_produto <> NEW.nome_produto OR OLD.valor_unitario <> NEW.valor_unitario OR OLD.ativo <> NEW.ativo THEN
    
        SET detalhes_log = CONCAT(
            'Produto ID ', OLD.id_produto, ' atualizado. ',
            IF(OLD.nome_produto <> NEW.nome_produto, CONCAT('Nome: "', OLD.nome_produto, '" -> "', NEW.nome_produto, '". '), ''),
            IF(OLD.valor_unitario <> NEW.valor_unitario, CONCAT('Valor: ', OLD.valor_unitario, ' -> ', NEW.valor_unitario, '. '), ''),
            IF(OLD.ativo <> NEW.ativo, CONCAT('Status Ativo: ', IF(OLD.ativo, 'VERDADEIRO', 'FALSO'), ' -> ', IF(NEW.ativo, 'VERDADEIRO', 'FALSO'), '.'), '')
        );
        
        INSERT INTO Log_Eventos (tabela_afetada, id_registro_afetado, acao_realizada, id_usuario_logado, descricao)
        VALUES ('Produto', OLD.id_produto, 'UPDATE', CURRENT_USER(), detalhes_log);
        
    END IF;
END$$
DELIMITER ;

-- ============================================
-- 				Stored Procedures
-- ============================================
DELIMITER $$
CREATE PROCEDURE sp_RegistrarMovimentacao(
    IN p_id_estoque INT,
    IN p_id_produto INT,
    IN p_tipo ENUM('ENTRADA', 'SAIDA', 'AJUSTE'),
    IN p_quantidade NUMERIC(14,3),
    IN p_id_usuario INT,
    IN p_observacao TEXT
)
BEGIN
    INSERT INTO Movimentacao (
        id_estoque, 
        id_produto, 
        tipo, 
        quantidade, 
        data_mov, 
        id_usuario, 
        observacao
    )
    VALUES (
        p_id_estoque, 
        p_id_produto, 
        p_tipo, 
        p_quantidade, 
        NOW(),
        p_id_usuario, 
        p_observacao
    );

END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_ConsultarEstoqueProduto(
    IN p_id_produto INT
)
BEGIN
    SELECT 
        p.id_produto,
        p.nome_produto,
        e.id_estoque,
        e.nome AS nome_estoque,
        s.nome_sala,
        ep.quantidade_atual,
        ep.quantidade_minima
    FROM Estoque_Produto AS ep
    JOIN Produto AS p ON ep.id_produto = p.id_produto
    JOIN Estoque AS e ON ep.id_estoque = e.id_estoque
    JOIN Sala AS s ON e.id_sala = s.id_sala
    WHERE ep.id_produto = p_id_produto;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE sp_VerificarEstoqueMinimo()
BEGIN
    SELECT 
        p.id_produto,
        p.nome_produto,
        e.nome AS nome_estoque,
        ep.quantidade_atual,
        ep.quantidade_minima,
        (ep.quantidade_minima - ep.quantidade_atual) AS quantidade_a_repor
    FROM Estoque_Produto AS ep
    JOIN Produto AS p ON ep.id_produto = p.id_produto
    JOIN Estoque AS e ON ep.id_estoque = e.id_estoque
    WHERE ep.quantidade_atual < ep.quantidade_minima;
END$$
DELIMITER ;