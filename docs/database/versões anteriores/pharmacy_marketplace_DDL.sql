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
