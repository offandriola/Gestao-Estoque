CREATE TABLE `Responsavel` (
  `id_resp` int PRIMARY KEY,
  `nome` varchar(120) NOT NULL,
  `email` varchar(320) UNIQUE,
  `telefone` varchar(20),
  `cargo` varchar(40)
);

CREATE TABLE `Sala` (
  `id_sala` int PRIMARY KEY AUTO_INCREMENT,
  `nome_sala` varchar(80) NOT NULL,
  `localizacao` varchar(120),
  `id_resp` int NOT NULL
);

CREATE TABLE `Estoque` (
  `id_estoque` int PRIMARY KEY AUTO_INCREMENT,
  `id_sala` int NOT NULL,
  `nome` varchar(80) NOT NULL,
  `data_criacao` date,
  `status` varchar(20) DEFAULT 'ATIVO'
);

CREATE TABLE `Categoria_Produto` (
  `id_categoria` int PRIMARY KEY AUTO_INCREMENT,
  `nome_cat` varchar(60) UNIQUE NOT NULL,
  `sub_cat` varchar(60) UNIQUE NOT NULL,
  `descricao_produto` text
);

CREATE TABLE `Produto` (
  `id_produto` int PRIMARY KEY AUTO_INCREMENT,
  `nome_produto` varchar(120) NOT NULL,
  `id_categoria` int NOT NULL,
  `valor_unitario` numeric(14,2) NOT NULL,
  `unidade_medida` varchar(15),
  `ativo` boolean NOT NULL DEFAULT true
);

CREATE TABLE `Estoque_Produto` (
  `id_estoque` int NOT NULL,
  `id_produto` int NOT NULL,
  `quantidade_atual` numeric(14,3) NOT NULL,
  `quantidade_minima` numeric(14,3) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_estoque`, `id_produto`)
);

CREATE TABLE `Usuario` (
  `id_usuario` int PRIMARY KEY AUTO_INCREMENT,
  `nome` varchar(120) NOT NULL,
  `email` varchar(320) UNIQUE,
  `cargo` ENUM ('ADMIN', 'OPERADOR')
);

CREATE TABLE `Movimentacao` (
  `id_mov` int PRIMARY KEY AUTO_INCREMENT,
  `id_estoque` int NOT NULL,
  `id_produto` int NOT NULL,
  `tipo` ENUM ('ENTRADA', 'SAIDA', 'AJUSTE') NOT NULL,
  `quantidade` numeric(14,3) NOT NULL,
  `data_mov` timestamp NOT NULL,
  `id_usuario` int,
  `observacao` text
);

CREATE TABLE `Fornecedor` (
  `id_forn` int PRIMARY KEY AUTO_INCREMENT,
  `razao_social` varchar(160) NOT NULL,
  `cnpj` varchar(20) UNIQUE,
  `telefone` varchar(20),
  `email` varchar(320)
);

CREATE TABLE `Pedido_Compra` (
  `id_pedido` int PRIMARY KEY AUTO_INCREMENT,
  `id_forn` int NOT NULL,
  `data_pedido` date NOT NULL,
  `status` ENUM ('ABERTO', 'APROVADO', 'ENTREGUE') DEFAULT 'ABERTO',
  `valor_total` numeric(16,2) NOT NULL
);

CREATE TABLE `Pedido_Produto` (
  `id_pedido` int NOT NULL,
  `id_produto` int NOT NULL,
  `quantidade` numeric(14,3) NOT NULL,
  `valor_unitario` numeric(14,2) NOT NULL,
  PRIMARY KEY (`id_pedido`, `id_produto`)
);

CREATE INDEX `Estoque_Produto_index_0` ON `Estoque_Produto` (`id_produto`);

CREATE INDEX `Movimentacao_index_1` ON `Movimentacao` (`id_estoque`, `id_produto`, `data_mov`);

CREATE INDEX `Movimentacao_index_2` ON `Movimentacao` (`id_usuario`);

CREATE INDEX `Pedido_Compra_index_3` ON `Pedido_Compra` (`id_forn`);

CREATE INDEX `Pedido_Produto_index_4` ON `Pedido_Produto` (`id_produto`);

ALTER TABLE `Responsavel` COMMENT = 'Quem gerencia uma ou mais Salas.';

ALTER TABLE `Sala` COMMENT = 'Ambiente físico que possui Estoques.';

ALTER TABLE `Estoque` COMMENT = 'Agrupa itens por sala/finalidade (status: ATIVO/INATIVO).';

ALTER TABLE `Categoria_Produto` COMMENT = 'Taxonomia para classificar Itens.';

ALTER TABLE `Produto` COMMENT = 'Recurso estocado/comprado (SKU).';

ALTER TABLE `Estoque_Produto` COMMENT = 'Relação N:N entre Estoque e Item + saldos.';

ALTER TABLE `Usuario` COMMENT = 'Usuário que executa movimentações (retirada/entrada/ajuste).';

ALTER TABLE `Movimentacao` COMMENT = 'Histórico de entradas, saídas e ajustes.';

ALTER TABLE `Fornecedor` COMMENT = 'Fornecedor de itens.';

ALTER TABLE `Pedido_Compra` COMMENT = 'Ordem de compra vinculada a um fornecedor.';

ALTER TABLE `Pedido_Produto` COMMENT = 'Itens que compõem cada pedido de compra.';

ALTER TABLE `Sala` ADD FOREIGN KEY (`id_resp`) REFERENCES `Responsavel` (`id_resp`);

ALTER TABLE `Estoque` ADD FOREIGN KEY (`id_sala`) REFERENCES `Sala` (`id_sala`);

ALTER TABLE `Produto` ADD FOREIGN KEY (`id_categoria`) REFERENCES `Categoria_Produto` (`id_categoria`);

ALTER TABLE `Estoque_Produto` ADD FOREIGN KEY (`id_estoque`) REFERENCES `Estoque` (`id_estoque`);

ALTER TABLE `Estoque_Produto` ADD FOREIGN KEY (`id_produto`) REFERENCES `Produto` (`id_produto`);

ALTER TABLE `Movimentacao` ADD FOREIGN KEY (`id_estoque`) REFERENCES `Estoque` (`id_estoque`);

ALTER TABLE `Movimentacao` ADD FOREIGN KEY (`id_produto`) REFERENCES `Produto` (`id_produto`);

ALTER TABLE `Movimentacao` ADD FOREIGN KEY (`id_usuario`) REFERENCES `Usuario` (`id_usuario`);

ALTER TABLE `Pedido_Compra` ADD FOREIGN KEY (`id_forn`) REFERENCES `Fornecedor` (`id_forn`);

ALTER TABLE `Pedido_Produto` ADD FOREIGN KEY (`id_pedido`) REFERENCES `Pedido_Compra` (`id_pedido`);

ALTER TABLE `Pedido_Produto` ADD FOREIGN KEY (`id_produto`) REFERENCES `Produto` (`id_produto`);

ALTER TABLE `Responsavel` ADD FOREIGN KEY (`id_resp`) REFERENCES `Usuario` (`id_usuario`);
