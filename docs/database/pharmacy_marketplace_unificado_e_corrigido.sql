-- =====================================================================
-- Script DDL Completo para o Marketplace de Farmácia (Versão 2.0 Otimizada)
-- =====================================================================
-- Este script implementa o modelo relacional arquitetado, focando em
-- desempenho, segurança e escalabilidade. Ele usa uma estratégia de chave híbrida,
-- CONSTRAINTS nomeadas, e adere à 3FN.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS pharmacy_marketplace
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE pharmacy_marketplace;

-- =====================================================================
-- Seção 1: Usuários & Controle de Acesso
-- =====================================================================

-- Tabela central para todos os usuários do sistema (autenticação).
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id BINARY(16) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(72) NOT NULL, -- Projetado para Bcrypt
    phone_number VARCHAR(20) UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    deleted_at TIMESTAMP(6) NULL DEFAULT NULL, -- Para Soft Deletes
    
    -- Otimização: Constraints nomeadas e índices explícitos
    CONSTRAINT uq_users_public_id UNIQUE (public_id),
    CONSTRAINT uq_users_email UNIQUE (email),
    CONSTRAINT uq_users_phone_number UNIQUE (phone_number),
    INDEX idx_users_public_id (public_id),
    INDEX idx_users_deleted_at (deleted_at)
);

-- Define as funções (perfis) disponíveis no sistema (RBAC).
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,  -- Ex: 'ROLE_CUSTOMER', 'ROLE_PHARMACY_ADMIN'
    
    CONSTRAINT uq_roles_name UNIQUE (name)
);

-- Tabela de junção para atribuir funções aos usuários (Muitos-para-Muitos).
CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id INT NOT NULL,
    
    PRIMARY KEY (user_id, role_id),
    
    -- Otimização: ON DELETE RESTRICT para Soft Deletes 
    CONSTRAINT fk_user_roles_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_user_roles_role_id FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Otimização: Índice em FK 
    INDEX idx_user_roles_role_id (role_id)
);

-- =====================================================================
-- Seção 2: Entidades Centrais & Perfis
-- =====================================================================

-- Tabela de perfil para clientes.
CREATE TABLE IF NOT EXISTS customers (
    user_id BIGINT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    customer_type ENUM('INDIVIDUAL', 'LEGAL_ENTITY') NOT NULL,
    cpf VARCHAR(11) UNIQUE,
    cnpj VARCHAR(14) UNIQUE,
    birth_date DATE,
    
    CONSTRAINT fk_customers_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT uq_customers_cpf UNIQUE (cpf),
    CONSTRAINT uq_customers_cnpj UNIQUE (cnpj),
    CONSTRAINT chk_customer_type CHECK (
        (customer_type = 'INDIVIDUAL' AND cpf IS NOT NULL AND cnpj IS NULL) OR
        (customer_type = 'LEGAL_ENTITY' AND cnpj IS NOT NULL AND cpf IS NULL)
    )
);

-- Representa as entidades vendedoras (farmácias).
CREATE TABLE IF NOT EXISTS pharmacies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    legal_name VARCHAR(255) NOT NULL UNIQUE,
    trade_name VARCHAR(255) NOT NULL,
    cnpj VARCHAR(14) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    
    deleted_at TIMESTAMP(6) NULL DEFAULT NULL, -- Para Soft Deletes

    CONSTRAINT uq_pharmacies_legal_name UNIQUE (legal_name),
    CONSTRAINT uq_pharmacies_cnpj UNIQUE (cnpj),
    INDEX idx_pharmacies_deleted_at (deleted_at)
);

-- Tabela de perfil para funcionários de farmácias.
CREATE TABLE IF NOT EXISTS pharmacy_staff (
    user_id BIGINT PRIMARY KEY,
    pharmacy_id BIGINT NOT NULL,
    position VARCHAR(100) NOT NULL,
    
    CONSTRAINT fk_pharmacy_staff_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pharmacy_staff_pharmacies FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
     -- Otimização: Índice em FK
    INDEX idx_pharmacy_staff_pharmacy_id (pharmacy_id)
);

-- Tabela de perfil para entregadores.
CREATE TABLE IF NOT EXISTS delivery_personnel (
    user_id BIGINT PRIMARY KEY,
    cnh VARCHAR(11) NOT NULL UNIQUE,
    vehicle_details TEXT,
    
    CONSTRAINT fk_delivery_personnel_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT uq_delivery_personnel_cnh UNIQUE (cnh)
);

-- =====================================================================
-- Seção 3: Catálogo de Produtos
-- =====================================================================

-- Tabela para as marcas dos produtos
CREATE TABLE IF NOT EXISTS brands (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    
    CONSTRAINT uq_brands_name UNIQUE (name)
);

-- Tabela para os fabricantes dos produtos
CREATE TABLE IF NOT EXISTS manufacturers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    
    CONSTRAINT uq_manufacturers_name UNIQUE (name)
);

-- Tabela para os produtos
CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id BINARY(16) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    anvisa_code VARCHAR(20) UNIQUE,
    active_principle VARCHAR(255) NOT NULL,
    pharmaceutical_form VARCHAR(100),
    is_prescription_required BOOLEAN NOT NULL DEFAULT FALSE,
    controlled_substance_list VARCHAR(10), -- Ex: "A1", "B2", "C1" ref. Portaria 344/98
    brand_id BIGINT,
    manufacturer_id BIGINT,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    deleted_at TIMESTAMP(6) NULL DEFAULT NULL, -- Para Soft Deletes
    
    CONSTRAINT uq_products_public_id UNIQUE (public_id),
    CONSTRAINT uq_products_anvisa_code UNIQUE (anvisa_code),
    CONSTRAINT fk_products_brand_id FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_products_manufacturer_id FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_products_public_id (public_id),
    INDEX idx_products_deleted_at (deleted_at),
    
    -- Otimização: Índice em FK 
    INDEX idx_products_brand_id (brand_id),
    INDEX idx_products_manufacturer_id (manufacturer_id)
);

-- Tabela para cadastro dos produtos das farmacias e seus variantes
CREATE TABLE IF NOT EXISTS product_variants (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    dosage VARCHAR(50),
    package_size VARCHAR(50),
    gtin VARCHAR(14) UNIQUE,
    deleted_at TIMESTAMP(6) NULL DEFAULT NULL, -- Para Soft Deletes
    
    CONSTRAINT uq_product_variants_sku UNIQUE (sku),
    CONSTRAINT uq_product_variants_gtin UNIQUE (gtin),
    CONSTRAINT fk_product_variants_product_id FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_product_variants_deleted_at (deleted_at),
    
    
    -- Otimização: Índice em FK
    INDEX idx_product_variants_product_id (product_id)
);

-- Tabela para categoria dos produtos
CREATE TABLE IF NOT EXISTS categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT,
    
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL ON UPDATE CASCADE
);

-- Tabela que vincula os produtos com sua categoria
CREATE TABLE IF NOT EXISTS product_categories (
    product_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_product_categories_product_id FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_product_categories_category_id FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Otimização: Índice em FK 
    INDEX idx_product_categories_category_id (category_id)
);

-- =====================================================================
-- Seção 4: Inventário & Precificação
-- =====================================================================

-- Tabela do Inventario da Farmacia vinculada a ele
CREATE TABLE IF NOT EXISTS inventory (
    pharmacy_id BIGINT NOT NULL,
    product_variant_id BIGINT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 0,
    expiration_date DATE,
    updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    PRIMARY KEY (pharmacy_id, product_variant_id),
    CONSTRAINT fk_inventory_pharmacy_id FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_inventory_product_variant_id FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_inventory_product_variant_price (product_variant_id, price)
);

-- Tabela de Promoções
CREATE TABLE IF NOT EXISTS promotions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    discount_type ENUM('PERCENTAGE', 'FIXED_AMOUNT') NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    pharmacy_id BIGINT NOT NULL,
    
    CONSTRAINT fk_promotions_pharmacies FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Tabela das regras das promoções, a quem se a plica e sua condições
CREATE TABLE IF NOT EXISTS promotion_rules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    promotion_id BIGINT NOT NULL,
    rule_type VARCHAR(50) NOT NULL, -- Ex: 'MIN_CART_VALUE', 'CUSTOMER_GROUP'
    rule_value VARCHAR(255) NOT NULL,
    
    CONSTRAINT fk_promotion_rules_promotions FOREIGN KEY (promotion_id) REFERENCES promotions(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Tabela que vincula o que está em promoção com a promoção em si
CREATE TABLE IF NOT EXISTS promotion_targets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    promotion_id BIGINT NOT NULL,
    target_type ENUM('PRODUCT', 'CATEGORY', 'BRAND') NOT NULL,
    target_id BIGINT NOT NULL,
    
    CONSTRAINT fk_promotion_targets_promotions FOREIGN KEY (promotion_id) REFERENCES promotions(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- =====================================================================
-- Seção 5: Pedidos & Transações
-- =====================================================================

-- Tabela de Pedidos
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id BINARY(16) NOT NULL UNIQUE,
    order_code VARCHAR(20) UNIQUE,
    customer_id BIGINT NOT NULL,
    pharmacy_id BIGINT NOT NULL,
    order_status ENUM('PENDING', 'AWAITING_PAYMENT', 'AWAITING_PRESCRIPTION', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    subtotal_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    shipping_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    CONSTRAINT uq_orders_public_id UNIQUE (public_id),
    CONSTRAINT uq_orders_order_code UNIQUE (order_code),
    CONSTRAINT fk_orders_customer_id FOREIGN KEY (customer_id) REFERENCES customers(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_orders_pharmacy_id FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_orders_public_id (public_id),
    
    -- Otimização: Índice em FK 
    INDEX idx_orders_customer_id (customer_id),
    INDEX idx_orders_pharmacy_id (pharmacy_id)
);

-- Tabela dos Itens dos Pedidos
CREATE TABLE IF NOT EXISTS order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_variant_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    
    CONSTRAINT fk_order_items_orders FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_order_items_product_variants FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE RESTRICT ON UPDATE NO ACTION
);

-- Tabela de Prescrição médica para os produtos que precisão
CREATE TABLE IF NOT EXISTS prescriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    prescription_code VARCHAR(50) NOT NULL UNIQUE,
    doctor_crm VARCHAR(20) NOT NULL,
    file_path VARCHAR(255),
    status ENUM('PENDING_VALIDATION', 'VALIDATED', 'REJECTED') NOT NULL DEFAULT 'PENDING_VALIDATION',
    validated_by BIGINT,
    validated_at TIMESTAMP(6),
    
    CONSTRAINT fk_prescriptions_orders FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_prescriptions_pharmacy_staff FOREIGN KEY (validated_by) REFERENCES pharmacy_staff(user_id) ON DELETE RESTRICT ON UPDATE NO ACTION
);

-- Tabela de pagamentos de Um Pedido
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    status ENUM('PENDING', 'SUCCESSFUL', 'FAILED') NOT NULL DEFAULT 'PENDING',
    transaction_id VARCHAR(255) UNIQUE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    
    CONSTRAINT fk_payments_orders FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT ON UPDATE NO ACTION
);

-- =====================================================================
-- Seção 6: Atendimento & Logística
-- =====================================================================

-- Tabela de Endereços
CREATE TABLE IF NOT EXISTS addresses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    street VARCHAR(255) NOT NULL,
    complement VARCHAR(255),
    neighborhood VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    country VARCHAR(50) NOT NULL DEFAULT 'Brazil'
);

-- Tabela que vincula o Cliente com o seu Endereço
CREATE TABLE IF NOT EXISTS customer_addresses (
    customer_id BIGINT NOT NULL,
    address_id BIGINT NOT NULL,
    address_type ENUM('SHIPPING', 'BILLING', 'OTHER') NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    
    PRIMARY KEY (customer_id, address_id, address_type),
    CONSTRAINT fk_customer_addresses_customers FOREIGN KEY (customer_id) REFERENCES customers(user_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_customer_addresses_addresses FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Tabela de junção para endereços de farmácias (matriz/filiais)
CREATE TABLE IF NOT EXISTS pharmacy_locations (
    pharmacy_id BIGINT NOT NULL,
    address_id BIGINT NOT NULL,
    is_headquarters BOOLEAN NOT NULL DEFAULT FALSE, -- Identifica se é a matriz
    
    PRIMARY KEY (pharmacy_id, address_id),
    CONSTRAINT fk_pharmacy_locations_pharmacies FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_pharmacy_locations_addresses FOREIGN KEY (address_id) REFERENCES addresses(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Tabela de Entregas
CREATE TABLE IF NOT EXISTS deliveries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT NOT NULL UNIQUE,
    delivery_person_id BIGINT,
    shipping_address_id BIGINT NOT NULL,
    delivery_status ENUM('AWAITING_PICKUP', 'IN_TRANSIT', 'DELIVERED', 'FAILED_ATTEMPT') NOT NULL DEFAULT 'AWAITING_PICKUP',
    estimated_delivery_date DATE,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
    
    CONSTRAINT fk_deliveries_orders FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_deliveries_delivery_personnel FOREIGN KEY (delivery_person_id) REFERENCES delivery_personnel(user_id) ON DELETE SET NULL ON UPDATE NO ACTION,
    CONSTRAINT fk_deliveries_addresses FOREIGN KEY (shipping_address_id) REFERENCES addresses(id) ON DELETE RESTRICT ON UPDATE NO ACTION
);

-- =====================================================================
-- Seção 7: Carrinho de Compras (Nova Seção)
-- =====================================================================

-- Tabela para armazenar os itens no carrinho de compras de um cliente.
-- Esta tabela é transitória; seus registros são normalmente excluídos
-- após a conclusão de um pedido.
CREATE TABLE IF NOT EXISTS customer_cart_items (
    customer_id BIGINT NOT NULL,
    product_variant_id BIGINT NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    
    -- Chave primária composta garante que um cliente só tenha uma linha por variante de produto.
    PRIMARY KEY (customer_id, product_variant_id), 
    
    -- Chave estrangeira para o cliente. Se o cliente for excluído, seu carrinho também é.
    CONSTRAINT fk_cart_items_customers FOREIGN KEY (customer_id) REFERENCES customers(user_id) ON DELETE CASCADE ON UPDATE NO ACTION,
    
    -- Chave estrangeira para a variante do produto. Se a variante for excluída, ela some dos carrinhos.
    CONSTRAINT fk_cart_items_product_variants FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE ON UPDATE NO ACTION,

    -- Garante que a quantidade seja sempre positiva.
    CONSTRAINT chk_cart_item_quantity CHECK (quantity > 0)
);

-- =====================================================================
-- Seção 8: Avaliação (Novissíma Seção)
-- =====================================================================

-- Tabela para armazena avaliações de diversas entidades.
-- Um usuário pode avaliar produtos, pedidos, farmácias, entregas, outros usuários ou o sistema.
CREATE TABLE IF NOT EXISTS reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    -- FK para a tabela 'users'. Identifica QUEM está fazendo a avaliação.
    reviewer_id BIGINT NOT NULL,
    
    -- A nota da avaliação (ex: 1 a 5 estrelas).
    rating TINYINT UNSIGNED NOT NULL,
    
    -- Comentário opcional em texto.
    comment TEXT,
    
    -- O tipo de entidade que está sendo avaliada.
    reviewable_type ENUM(
        'PRODUCT_VARIANT', 
        'ORDER', 
        'DELIVERY', 
        'PHARMACY', 
        'USER', -- Para avaliar um cliente, um entregador ou um funcionário.
        'SYSTEM'  -- Para avaliação geral da plataforma/marketplace.
    ) NOT NULL,
    
    -- O ID da entidade que está sendo avaliada (ex: o ID do produto, o ID do pedido, etc.).
    -- É NULLABLE para casos como avaliação do 'SYSTEM', que não tem um ID específico.
    reviewable_id BIGINT, 
    
    -- Data da criação da avaliação.
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),

    -- Chave estrangeira para o autor da avaliação. Se o usuário for excluído, suas avaliações também serão.
    CONSTRAINT fk_reviews_reviewer FOREIGN KEY (reviewer_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    
    -- Garante que a nota da avaliação esteja sempre entre 1 e 5.
    CONSTRAINT chk_rating_range CHECK (rating >= 1 AND rating <= 5),

    -- Garante que o ID da entidade seja fornecido, a menos que seja uma avaliação do sistema.
    CONSTRAINT chk_reviewable_id CHECK (
        (reviewable_type != 'SYSTEM' AND reviewable_id IS NOT NULL) OR
        (reviewable_type = 'SYSTEM')
    ),

    -- Índice para buscar todas as avaliações de um item específico de forma muito rápida.
    INDEX idx_reviewable (reviewable_type, reviewable_id)
);

-- =====================================================================
-- Seção 9: Governança e Auditoria
-- =====================================================================

-- Tabela genérica para registrar todas as alterações em dados críticos.
CREATE TABLE IF NOT EXISTS audit_log (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(64) NOT NULL, -- 'Nome da tabela auditada',
    row_pk BIGINT NOT NULL, -- 'Chave primária do registro alterado',
    column_name VARCHAR(64) NOT NULL, -- 'Nome da coluna alterada',
    old_value TEXT, -- 'Valor antes da alteração',
    new_value TEXT, -- 'Valor após a alteração',
    changed_by_user_id BIGINT, -- 'ID do usuário que realizou a alteração (via session var)',
    changed_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    INDEX idx_audit_log_lookup (table_name, row_pk, changed_at)
);

-- =================================================================================================
-- SCRIPT DE POPULAÇÃO DE DADOS (DATA SEEDING) - PHARMACY MARKETPLACE
-- =================================================================================================

-- OBJETIVO:
-- Este script realiza uma limpeza completa e repopulação massiva do banco de dados e, em seguida,
-- simula a evolução e o ciclo de vida dos dados ao longo do tempo através de uma série de
-- operações de UPDATE, DELETE e Soft DELETE.

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 0: PREPARAÇÃO DO AMBIENTE E LIMPEZA DE DADOS
-- -------------------------------------------------------------------------------------------------
USE pharmacy_marketplace;
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE `audit_log`;
TRUNCATE TABLE `reviews`;
TRUNCATE TABLE `customer_cart_items`;
TRUNCATE TABLE `deliveries`;
TRUNCATE TABLE `pharmacy_locations`;
TRUNCATE TABLE `customer_addresses`;
TRUNCATE TABLE `addresses`;
TRUNCATE TABLE `payments`;
TRUNCATE TABLE `prescriptions`;
TRUNCATE TABLE `order_items`;
TRUNCATE TABLE `orders`;
TRUNCATE TABLE `promotion_targets`;
TRUNCATE TABLE `promotion_rules`;
TRUNCATE TABLE `promotions`;
TRUNCATE TABLE `inventory`;
TRUNCATE TABLE `product_categories`;
TRUNCATE TABLE `categories`;
TRUNCATE TABLE `product_variants`;
TRUNCATE TABLE `products`;
TRUNCATE TABLE `manufacturers`;
TRUNCATE TABLE `brands`;
TRUNCATE TABLE `delivery_personnel`;
TRUNCATE TABLE `pharmacy_staff`;
TRUNCATE TABLE `pharmacies`;
TRUNCATE TABLE `customers`;
TRUNCATE TABLE `user_roles`;
TRUNCATE TABLE `roles`;
TRUNCATE TABLE `users`;

SET FOREIGN_KEY_CHECKS = 1;

-- -------------------------------------------------------------------------------------------------
-- INÍCIO DA TRANSAÇÃO DE POPULAÇÃO INICIAL
-- -------------------------------------------------------------------------------------------------
START TRANSACTION;

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 1: DADOS FUNDAMENTAIS
-- -------------------------------------------------------------------------------------------------
INSERT INTO `roles` (`id`, `name`) VALUES
(1, 'ROLE_CUSTOMER'), (2, 'ROLE_PHARMACY_ADMIN'), (3, 'ROLE_PHARMACIST'),
(4, 'ROLE_DELIVERY_PERSONNEL'), (5, 'ROLE_SYS_ADMIN');

INSERT INTO `brands` (`id`, `name`) VALUES
(1, 'Neosaldina'), (2, 'Dorflex'), (3, 'Tylenol'), (4, 'Medley'), (5, 'EMS'),
(6, 'La Roche-Posay'), (7, 'Vichy'), (8, 'Cimed'), (9, 'Bayer'), (10, 'Pfizer'),
(11, 'GSK'), (12, 'Nivea'), (13, 'Colgate'), (14, 'Catarinense Pharma');

INSERT INTO `manufacturers` (`id`, `name`) VALUES
(1, 'Takeda Pharma'), (2, 'Sanofi'), (3, 'Johnson & Johnson'), (4, 'Medley Genéricos'),
(5, 'EMS Genéricos'), (6, 'L''Oréal'), (7, 'Grupo Cimed'), (8, 'Bayer S.A.'),
(9, 'Pfizer Inc.'), (10, 'GlaxoSmithKline'), (11, 'Beiersdorf'), (12, 'Colgate-Palmolive'),
(13, 'Laboratório Catarinense');

INSERT INTO `categories` (`id`, `name`, `parent_id`) VALUES
(1, 'Medicamentos', NULL), (2, 'Dermocosméticos', NULL), (3, 'Higiene Pessoal', NULL),
(4, 'Vitaminas e Suplementos', NULL), (5, 'Analgésicos', 1), (6, 'Anti-inflamatórios', 1),
(7, 'Antibióticos', 1), (8, 'Dor de Cabeça', 5), (9, 'Protetor Solar', 2),
(10, 'Cuidados com o Cabelo', 3), (11, 'Vitamina C', 4), (12, 'Saúde Infantil', NULL),
(13, 'Primeiros Socorros', NULL), (14, 'Higiene Bucal', 3), (15, 'Psicotrópicos', 1);

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 2: ENTIDADES CENTRAIS
-- -------------------------------------------------------------------------------------------------
INSERT INTO `addresses` (`id`, `street`, `complement`, `neighborhood`, `city`, `state`, `postal_code`) VALUES
(1, 'Avenida Paulista, 1500', 'Andar 10', 'Bela Vista', 'São Paulo', 'SP', '01310-200'),
(2, 'Rua da Consolação, 900', NULL, 'Consolação', 'São Paulo', 'SP', '01302-000'),
(3, 'Rua Oscar Freire, 550', 'Loja 3', 'Jardins', 'São Paulo', 'SP', '01426-000'),
(4, 'Avenida Rio Branco, 156', 'Sala 201', 'Centro', 'Rio de Janeiro', 'RJ', '20040-903'),
(5, 'Rua das Laranjeiras, 300', 'Apto 502', 'Laranjeiras', 'Rio de Janeiro', 'RJ', '22240-001'),
(6, 'Praça da Liberdade, 10', NULL, 'Funcionários', 'Belo Horizonte', 'MG', '30140-010'),
(7, 'Avenida Sete de Setembro, 2000', NULL, 'Vitória', 'Salvador', 'BA', '40080-001'),
(8, 'Rua das Flores, 100', 'Apto 101', 'Centro', 'Curitiba', 'PR', '80010-100'),
(9, 'Avenida Borges de Medeiros, 500', 'Conjunto 303', 'Centro Histórico', 'Porto Alegre', 'RS', '90020-020');

INSERT INTO `pharmacies` (`id`, `legal_name`, `trade_name`, `cnpj`, `phone`, `email`) VALUES
(1, 'Pharma-Life Comércio de Medicamentos Ltda.', 'Pharma-Life Matriz', '11222333000144', '1133334444', 'contato@pharmalife.com'),
(2, 'Drogaria Bem-Estar e Saúde S.A.', 'Drogaria Bem-Estar', '55666777000188', '11988887777', 'atendimento@bemestar.com'),
(3, 'Farmácia Popular MG Ltda.', 'Farmácia Popular BH', '88999000000111', '3132325555', 'contato@farmapopularbh.com'),
(4, 'Drogarias FarmaSsa Ltda.', 'FarmaSsa Pelourinho', '12121212000122', '7133211234', 'contato@farmassa.com.br'),
(5, 'Rede de Farmácias SulFarma S.A.', 'SulFarma POA', '34343434000133', '5132255678', 'contato@sulfarma.com');

INSERT INTO `pharmacy_locations` (`pharmacy_id`, `address_id`, `is_headquarters`) VALUES
(1, 1, TRUE), (2, 2, TRUE), (3, 6, TRUE), (4, 7, TRUE), (5, 9, TRUE);

INSERT INTO `users` (`id`, `public_id`, `email`, `hashed_password`, `phone_number`) VALUES
(1, UUID_TO_BIN(UUID()), 'ana.silva@email.com', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '11911112222'),
(2, UUID_TO_BIN(UUID()), 'bruno.costa@pharmalife.com', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '11933334444'),
(3, UUID_TO_BIN(UUID()), 'carlos.dias@delivery.com', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '11955556666'),
(4, UUID_TO_BIN(UUID()), 'compras@construtorarj.com.br', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '21999998888'),
(5, UUID_TO_BIN(UUID()), 'fernanda.souza@bemestar.com', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '11966665555'),
(6, UUID_TO_BIN(UUID()), 'joao.pereira@email.com', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '71988776655'),
(7, UUID_TO_BIN(UUID()), 'lucas.moura@farmassa.com.br', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '71988771122'),
(8, UUID_TO_BIN(UUID()), 'helena.ribeiro@delivery.com', '$2a$10$fPL.8g545yCMj251y4.yX.C8zXb.2T2.L1Qz1Qz1Qz1Qz1Qz1', '41977665544');

INSERT INTO `customers` (`user_id`, `full_name`, `customer_type`, `cpf`, `cnpj`) VALUES
(1, 'Ana Silva', 'INDIVIDUAL', '11122233344', NULL),
(4, 'Construtora RJ Ltda', 'LEGAL_ENTITY', NULL, '22333444000155'),
(6, 'João Pereira', 'INDIVIDUAL', '55566677788', NULL);

INSERT INTO `user_roles` (`user_id`, `role_id`) VALUES
(1, 1), (2, 2), (2, 3), (3, 4), (4, 1), (5, 3), (6, 1), (7, 2), (7, 3), (8, 4);

INSERT INTO `pharmacy_staff` (`user_id`, `pharmacy_id`, `position`) VALUES
(2, 1, 'Farmacêutico Responsável'), (5, 2, 'Farmacêutica'), (7, 4, 'Gerente Farmacêutico');

INSERT INTO `delivery_personnel` (`user_id`, `cnh`, `vehicle_details`) VALUES
(3, '12345678901', 'Moto Honda CG 160 - Placa ABC-1234'),
(8, '98765432109', 'Carro Fiat Fiorino - Placa XYZ-9876');

INSERT INTO `customer_addresses` (`customer_id`, `address_id`, `address_type`, `is_default`) VALUES
(1, 3, 'SHIPPING', TRUE), (1, 5, 'OTHER', FALSE), (4, 4, 'BILLING', TRUE), (6, 8, 'SHIPPING', TRUE);

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 3: CATÁLOGO DE PRODUTOS E INVENTÁRIO
-- -------------------------------------------------------------------------------------------------
INSERT INTO `products` (`id`, `public_id`, `name`, `active_principle`, `is_prescription_required`, `brand_id`, `manufacturer_id`) VALUES
(1, UUID_TO_BIN(UUID()), 'Dipirona Sódica', 'Dipirona Sódica', FALSE, 2, 2),
(3, UUID_TO_BIN(UUID()), 'Protetor Solar Facial Anthelios', 'Mexoryl XL', FALSE, 6, 6),
(4, UUID_TO_BIN(UUID()), 'Vitamina C Redoxon', 'Ácido Ascórbico', FALSE, 9, 8),
(5, UUID_TO_BIN(UUID()), 'Shampoo Anticaspa Dercos', 'Selênio DS', FALSE, 7, 6),
(6, UUID_TO_BIN(UUID()), 'Ibuprofeno 400mg', 'Ibuprofeno', FALSE, 5, 5),
(7, UUID_TO_BIN(UUID()), 'Creme Dental Colgate Total 12', 'Fluoreto de Estanho', FALSE, 13, 12),
(8, UUID_TO_BIN(UUID()), 'Ômega 3', 'Óleo de Peixe', FALSE, 14, 13);

INSERT INTO `products` (`id`, `public_id`, `name`, `active_principle`, `is_prescription_required`, `controlled_substance_list`, `brand_id`, `manufacturer_id`) VALUES
(2, UUID_TO_BIN(UUID()), 'Amoxicilina 500mg', 'Amoxicilina Tri-hidratada', TRUE, 'C1', 4, 4),
(9, UUID_TO_BIN(UUID()), 'Clonazepam 2mg', 'Clonazepam', TRUE, 'B1', 5, 5),
(10, UUID_TO_BIN(UUID()), 'Zolpidem 10mg', 'Hemitartarato de Zolpidem', TRUE, 'B1', 2, 2);

INSERT INTO `product_variants` (`id`, `product_id`, `sku`, `dosage`, `package_size`, `gtin`) VALUES
(1, 1, 'DIP500CP20', '500mg', '20 Comprimidos', '7891058001325'),
(2, 1, 'DIPGOTAS20', '500mg/ml', 'Gotas 20ml', '7891058001332'),
(3, 2, 'AMX500CAP21', '500mg', '21 Cápsulas', '7896422505278'),
(4, 3, 'LRP-ANTH-CC-60', NULL, 'Com Cor FPS 60 - 50g', '7899706159021'),
(5, 3, 'LRP-ANTH-SC-60', NULL, 'Sem Cor FPS 60 - 50g', '7899706159038'),
(6, 4, 'RDX-1G-30CP', '1g', '30 Comprimidos Efervescentes', '7891106910258'),
(7, 5, 'VCH-DRC-200ML', NULL, '200ml', '7899706134127'),
(8, 6, 'IBU400-10CP', '400mg', '10 Comprimidos', '7891058021484'),
(9, 7, 'COL-T12-90G', NULL, '90g', '7891024132988'),
(10, 8, 'CAT-OMG3-120CAP', '1000mg', '120 Cápsulas', '7896023704231'),
(11, 9, 'CLO2MG-20CP', '2mg', '20 Comprimidos', '7896004705359'),
(12, 10, 'ZOL10MG-30CP', '10mg', '30 Comprimidos', '7891058019689');

INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES
(1, 1), (1, 5), (2, 1), (2, 7), (3, 2), (3, 9), (4, 4), (4, 11),
(5, 2), (5, 3), (5, 10), (6, 1), (6, 6), (7, 3), (7, 14), (8, 4),
(9, 1), (9, 15), (10, 1), (10, 15);

INSERT INTO `inventory` (`pharmacy_id`, `product_variant_id`, `price`, `quantity`) VALUES
(1, 1, 15.50, 100), (1, 3, 45.00, 30), (1, 6, 35.90, 40), (1, 8, 22.50, 70), (1, 11, 18.90, 25),
(2, 1, 14.99, 80), (2, 4, 89.90, 120), (2, 5, 85.50, 0), (2, 7, 65.75, 60), (2, 9, 5.99, 250),
(3, 1, 16.00, 200), (3, 6, 34.50, 75), (3, 7, 68.00, 25), (3, 8, 21.99, 100),
(4, 1, 15.80, 150), (4, 9, 6.50, 300), (4, 10, 65.00, 50), (4, 12, 55.75, 15),
(5, 1, 15.25, 90), (5, 8, 23.00, 80), (5, 10, 68.50, 40), (5, 11, 17.50, 35);

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 4: CARRINHOS DE COMPRAS ATIVOS
-- -------------------------------------------------------------------------------------------------
INSERT INTO `customer_cart_items` (`customer_id`, `product_variant_id`, `quantity`) VALUES
(1, 7, 1), (1, 6, 2), (6, 9, 3), (6, 10, 1);

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 5: SIMULAÇÃO DE FLUXOS DE NEGÓCIO
-- -------------------------------------------------------------------------------------------------
INSERT INTO `orders` (`id`, `public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `shipping_amount`, `total_amount`, `created_at`, `updated_at`) VALUES
(1, UUID_TO_BIN(UUID()), 'MKP-2025-00001', 1, 2, 'DELIVERED', 29.98, 5.00, 34.98, '2025-09-25 10:00:00', '2025-09-26 14:00:00');
INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES (1, 1, 2, 14.99);
INSERT INTO `payments` (`order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES (1, 34.98, 'CREDIT_CARD', 'SUCCESSFUL', 'txn_1a2b3c4d5e6f');
INSERT INTO `deliveries` (`id`, `order_id`, `delivery_person_id`, `shipping_address_id`, `delivery_status`) VALUES (1, 1, 3, 3, 'DELIVERED');

INSERT INTO `orders` (`id`, `public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `shipping_amount`, `total_amount`) VALUES
(2, UUID_TO_BIN(UUID()), 'MKP-2025-00002', 1, 1, 'AWAITING_PAYMENT', 45.00, 7.50, 52.50);
INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES (2, 3, 1, 45.00);
INSERT INTO `prescriptions` (`id`, `order_id`, `prescription_code`, `doctor_crm`, `status`, `validated_by`, `validated_at`) VALUES
(1, 2, 'REC2025-XYZ-987', 'SP123456', 'VALIDATED', 2, NOW() - INTERVAL 1 DAY);

INSERT INTO `promotions` (`id`, `name`, `discount_type`, `discount_value`, `start_date`, `end_date`, `pharmacy_id`) VALUES
(1, '10% Off Dermocosméticos', 'PERCENTAGE', 10.00, NOW() - INTERVAL 10 DAY, NOW() + INTERVAL 20 DAY, 2);
INSERT INTO `promotion_targets` (`promotion_id`, `target_type`, `target_id`) VALUES (1, 'CATEGORY', 2);
INSERT INTO `promotion_rules` (`promotion_id`, `rule_type`, `rule_value`) VALUES (1, 'MIN_CART_VALUE', '50.00');

SET @subtotal_p3 = 89.90 * 5; SET @discount_p3 = @subtotal_p3 * 0.10; SET @total_p3 = @subtotal_p3 - @discount_p3 + 25.00;
INSERT INTO `orders` (`id`, `public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `discount_amount`, `shipping_amount`, `total_amount`) VALUES
(3, UUID_TO_BIN(UUID()), 'MKP-2025-00003', 4, 2, 'PROCESSING', @subtotal_p3, @discount_p3, 25.00, @total_p3);
INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES (3, 4, 5, 89.90);
INSERT INTO `payments` (`order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES (3, @total_p3, 'BANK_SLIP', 'SUCCESSFUL', 'txn_7g8h9i0j1k2l');

INSERT INTO `orders` (`id`, `public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `shipping_amount`, `total_amount`) VALUES
(4, UUID_TO_BIN(UUID()), 'MKP-2025-00004', 1, 1, 'CANCELLED', 35.90, 5.00, 40.90);
INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES (4, 6, 1, 35.90);
INSERT INTO `payments` (`order_id`, `amount`, `payment_method`, `status`) VALUES (4, 40.90, 'CREDIT_CARD', 'PENDING');

INSERT INTO `promotions` (`id`, `name`, `discount_type`, `discount_value`, `start_date`, `end_date`, `pharmacy_id`) VALUES
(2, 'Leve 2 Cremes Dentais por R$10', 'FIXED_AMOUNT', 10.00, NOW() - INTERVAL 5 DAY, NOW() + INTERVAL 5 DAY, 4);
INSERT INTO `promotion_targets` (`promotion_id`, `target_type`, `target_id`) VALUES (2, 'PRODUCT', 9);
INSERT INTO `promotion_rules` (`promotion_id`, `rule_type`, `rule_value`) VALUES (2, 'MIN_QUANTITY', '2');

SET @subtotal_p5 = (6.50 * 2) + 65.00; SET @discount_p5 = (6.50*2) - 10.00; SET @total_p5 = @subtotal_p5 - @discount_p5 + 15.00;
INSERT INTO `orders` (`id`, `public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `discount_amount`, `shipping_amount`, `total_amount`) VALUES
(5, UUID_TO_BIN(UUID()), 'MKP-2025-00005', 6, 4, 'SHIPPED', @subtotal_p5, @discount_p5, 15.00, @total_p5);
INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES (5, 9, 2, 6.50), (5, 10, 1, 65.00);
INSERT INTO `payments` (`order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES (5, @total_p5, 'PIX', 'SUCCESSFUL', 'txn_pix_3m4n5o6p');
INSERT INTO `deliveries` (`id`, `order_id`, `delivery_person_id`, `shipping_address_id`, `delivery_status`) VALUES (2, 5, 8, 8, 'IN_TRANSIT');
INSERT INTO `prescriptions` (`id`, `order_id`, `prescription_code`, `doctor_crm`, `status`, `validated_by`, `validated_at`) VALUES
(2, 5, 'REC2025-ABC-123', 'BA654321', 'VALIDATED', 7, NOW() - INTERVAL 2 HOUR);

INSERT INTO `orders` (`id`, `public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `shipping_amount`, `total_amount`) VALUES
(6, UUID_TO_BIN(UUID()), 'MKP-2025-00006', 6, 5, 'CANCELLED', 17.50, 8.00, 25.50);
INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES (6, 11, 1, 17.50);
INSERT INTO `prescriptions` (`id`, `order_id`, `prescription_code`, `doctor_crm`, `status`, `validated_by`, `validated_at`) VALUES
(3, 6, 'REC2025-DEF-456', 'RS112233', 'REJECTED', 5, NOW() - INTERVAL 1 HOUR);

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 6: ENGAJAMENTO
-- -------------------------------------------------------------------------------------------------
INSERT INTO `reviews` (`reviewer_id`, `rating`, `comment`, `reviewable_type`, `reviewable_id`) VALUES
(1, 5, 'Produto excelente, aliviou minha dor de cabeça rapidamente.', 'PRODUCT_VARIANT', 1),
(1, 4, 'O entregador foi rápido e cordial.', 'DELIVERY', 1),
(1, 5, 'Ótimo preço na Drogaria Bem-Estar para este produto!', 'PHARMACY', 2),
(4, 5, 'Compra em volume para nossos funcionários. Processo simples e entrega rápida.', 'ORDER', 3),
(1, 5, 'A plataforma é muito fácil de usar e comparar preços.', 'SYSTEM', NULL),
(6, 3, 'O produto é bom, mas a entrega demorou um pouco mais que o esperado.', 'ORDER', 5),
(6, 1, 'Minha receita foi rejeitada e não entendi o motivo. Experiência frustrante.', 'ORDER', 6),
(1, 4, 'Gosto muito deste shampoo, sempre compro.', 'PRODUCT_VARIANT', 7);

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 7: GOVERNANÇA E CICLO DE VIDA DOS DADOS
-- -------------------------------------------------------------------------------------------------
UPDATE `users` SET `deleted_at` = NOW() WHERE `id` = 3;
UPDATE `pharmacies` SET `deleted_at` = NOW() WHERE `id` = 3;

INSERT INTO `audit_log` (`table_name`, `row_pk`, `column_name`, `old_value`, `new_value`, `changed_by_user_id`) VALUES
('inventory', 3, 'price', '45.00', '47.50', 2),
('inventory', 1, 'quantity', '100', '150', 2),
('users', 3, 'is_active', '1', '0', 5);
UPDATE `inventory` SET `price` = 47.50 WHERE `pharmacy_id` = 1 AND `product_variant_id` = 3;
UPDATE `inventory` SET `quantity` = 150 WHERE `pharmacy_id` = 1 AND `product_variant_id` = 1;

-- -------------------------------------------------------------------------------------------------
-- FIM DA TRANSAÇÃO DE POPULAÇÃO INICIAL
-- -------------------------------------------------------------------------------------------------
COMMIT;

-- =================================================================================================
-- SEÇÃO 8: SIMULAÇÃO DE EVOLUÇÃO DE DADOS (UPDATES & DELETES)
-- =================================================================================================
-- Esta seção simula as operações que ocorreriam no banco de dados após a carga inicial,
-- representando o uso diário da plataforma.
-- =================================================================================================

-- Inicia uma nova transação para as operações de evolução.
START TRANSACTION;

-- Cenário 1: Progressão de um Pedido
-- O Pedido 3 da Construtora RJ, que estava 'PROCESSING', agora foi enviado.
UPDATE `orders` SET `order_status` = 'SHIPPED' WHERE `id` = 3;
INSERT INTO `deliveries` (`order_id`, `delivery_person_id`, `shipping_address_id`, `delivery_status`, `estimated_delivery_date`)
VALUES (3, 8, 4, 'AWAITING_PICKUP', CURDATE() + INTERVAL 3 DAY);
-- Algum tempo depois, a entrega é concluída.
UPDATE `deliveries` SET `delivery_status` = 'DELIVERED' WHERE `order_id` = 3;
UPDATE `orders` SET `order_status` = 'DELIVERED' WHERE `id` = 3;

-- Cenário 2: Gestão de Inventário
-- A Drogaria Bem-Estar recebeu um novo lote do Protetor Solar sem cor (ID 5) que estava esgotado.
UPDATE `inventory` SET `quantity` = 100 WHERE `pharmacy_id` = 2 AND `product_variant_id` = 5;
-- Devido à alta demanda, a mesma farmácia decide aumentar o preço do Creme Dental Colgate.
UPDATE `inventory` SET `price` = 6.49 WHERE `pharmacy_id` = 2 AND `product_variant_id` = 9;
-- A alteração de preço é registrada na auditoria (simulando um trigger).
INSERT INTO `audit_log` (`table_name`, `row_pk`, `column_name`, `old_value`, `new_value`, `changed_by_user_id`)
VALUES ('inventory', 9, 'price', '5.99', '6.49', 5);

-- Cenário 3: Interação do Cliente
-- O cliente João Pereira (ID 6) remove o Ômega 3 (ID 10) de seu carrinho.
-- Este é um caso para HARD DELETE, pois a informação do carrinho é volátil.
DELETE FROM `customer_cart_items` WHERE `customer_id` = 6 AND `product_variant_id` = 10;
-- O mesmo cliente decide mudar seu endereço de entrega padrão para um novo endereço em Curitiba.
UPDATE `customer_addresses` SET `is_default` = FALSE WHERE `customer_id` = 6 AND `is_default` = TRUE;
UPDATE `customer_addresses` SET `is_default` = TRUE WHERE `customer_id` = 6 AND `address_id` = 8;

-- Cenário 4: Gestão de Marketing
-- A FarmaSsa (ID 4) decide estender a promoção do creme dental por mais 10 dias.
UPDATE `promotions` SET `end_date` = `end_date` + INTERVAL 10 DAY WHERE `id` = 2;

-- Cenário 5: Soft Deletes Estratégicos
-- A variante de Dipirona em Gotas (ID 2) foi descontinuada pelo fabricante.
-- Usamos um SOFT DELETE para removê-la das buscas, mas manter o histórico de pedidos que a continham.
UPDATE `product_variants` SET `deleted_at` = NOW() WHERE `id` = 2;
-- O funcionário Lucas Moura (ID 7) da FarmaSsa pediu demissão.
-- Seu usuário é desativado via SOFT DELETE para manter o histórico de validações que ele possa ter feito.
UPDATE `users` SET `deleted_at` = NOW(), `is_active` = FALSE WHERE `id` = 7;
-- A auditoria registra a desativação.
INSERT INTO `audit_log` (`table_name`, `row_pk`, `column_name`, `old_value`, `new_value`, `changed_by_user_id`)
VALUES ('users', 7, 'is_active', '1', '0', 2); -- Supondo que Bruno (Admin) fez a alteração.

-- Finaliza a transação das operações de evolução.
COMMIT;

-- =================================================================================================
-- FIM DO SCRIPT DE POPULAÇÃO EVOLUTIVO
-- =================================================================================================
