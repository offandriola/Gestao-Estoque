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
  id_resp int NOT NULL
);

CREATE TABLE Estoque (
  id_estoque int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  id_sala int NOT NULL,
  nome varchar(80) NOT NULL,
  data_criacao date,
  status varchar(20) DEFAULT 'ATIVO'
);

CREATE TABLE Categoria_Produto (
  id_categoria int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nome_cat varchar(60) UNIQUE NOT NULL,
  sub_cat varchar(60) UNIQUE NOT NULL,
  descricao_produto text
);

CREATE TABLE Produto (
  id_produto int UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  nome_produto varchar(120) NOT NULL,
  id_categoria int NOT NULL,
  valor_unitario numeric(14,2) NOT NULL,
  unidade_medida varchar(15),
  ativo boolean NOT NULL DEFAULT true
);

CREATE TABLE Estoque_Produto (
  id_estoque int NOT NULL,
  id_produto int NOT NULL,
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
  id_estoque int NOT NULL,
  id_produto int NOT NULL,
  tipo ENUM ('ENTRADA', 'SAIDA', 'AJUSTE') NOT NULL,
  quantidade numeric(14,3) NOT NULL,
  data_mov timestamp NOT NULL,
  id_usuario int,
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
  id_forn int NOT NULL,
  data_pedido date NOT NULL,
  status ENUM ('ABERTO', 'APROVADO', 'ENTREGUE') DEFAULT 'ABERTO',
  valor_total numeric(16,2) NOT NULL
);

CREATE TABLE Pedido_Produto (
  id_pedido int NOT NULL,
  id_produto int NOT NULL,
  quantidade numeric(14,3) NOT NULL,
  valor_unitario numeric(14,2) NOT NULL,
  PRIMARY KEY (id_pedido, id_produto)
);

CREATE TABLE Fornecedor_Produto (
  id_forn int UNSIGNED NOT NULL,
  id_produto int UNSIGNED NOT NULL,
  preco_custo numeric(14,2),
  codigo_produto_fornecedor varchar(50),
  PRIMARY KEY (id_forn, id_produto),
  FOREIGN KEY (id_forn) REFERENCES Fornecedor(id_forn),
  FOREIGN KEY (id_produto) REFERENCES Produto(id_produto)
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
-- 				  Comentários
-- ============================================
ALTER TABLE Responsavel COMMENT = 'Quem gerencia uma ou mais Salas.';
ALTER TABLE Sala COMMENT = 'Ambiente físico que possui Estoques.';
ALTER TABLE Estoque COMMENT = 'Agrupa itens por sala/finalidade (status: ATIVO/INATVIO).';
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
ALTER TABLE Responsavel ADD FOREIGN KEY (id_resp) REFERENCES Usuario (id_usuario);

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
    ELSEIF NEW.tipo = 'SAIDA' OR NEW.tipo = 'AJUSTE' THEN
        UPDATE Estoque_Produto
        SET quantidade_atual = quantidade_atual - NEW.quantidade
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

    IF NEW.tipo = 'SAIDA' OR NEW.tipo = 'AJUSTE' THEN
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