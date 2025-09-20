# Gestão de Estoque (MySQL)
Modelo relacional para controle de salas, estoques, produtos, pedidos de compra e movimentações.
Foco em integridade referencial, histórico de movimentações e consulta de saldos por produto/estoque.

# 📦 Estrutura (tabelas principais)
- Usuario → quem opera o sistema (ADMIN/OPERADOR).

- Responsavel → subtipo 1:1 de Usuario (responsável por Sala).

- Sala → local físico.

- Estoque → agrupador por sala/finalidade.

- Categoria_Produto / Produto → taxonomia e SKUs.

- Estoque_Produto → relação N:N (estoque × produto) + saldos.

- Movimentacao → entradas/saídas/ajustes (histórico).

- Fornecedor, Pedido_Compra, Pedido_Produto → compras por fornecedor.

# Cardinalidades (resumo):

- Usuario 1:1 Responsavel

- Responsavel 1:N Sala

- Sala 1:N Estoque

- Estoque N:N Produto (via Estoque_Produto)

- Produto 1:N Movimentacao

- Fornecedor 1:N Pedido_Compra; Pedido_Compra 1:N Pedido_Produto

# 🗂️ Requisitos
- Arquivo: gestao_estoque.sql → DDL completo (tabelas, índices, FKs, comentários).

- MySQL Workbench 8.0 CE

- WampServer 3.3.7
