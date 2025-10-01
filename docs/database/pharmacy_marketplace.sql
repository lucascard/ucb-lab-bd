-- =====================================================================
-- Script DDL Completo para o Marketplace de Farmácia
-- =====================================================================
-- Este script implementa o modelo relacional arquitetado, focando em
-- desempenho, segurança e escalabilidade. Ele usa uma estratégia de chave híbrida
-- (BIGINT AUTO_INCREMENT para chaves internas, BINARY(16) para IDs públicos)
-- e adere à 3FN.
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
    public_id BINARY(16) NOT NULL UNIQUE, -- Projetado para UUID
    email VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(72) NOT NULL, -- Projetado para Bcrypt
    phone_number VARCHAR(20) UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT(TRUE),
    created_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()),
    updated_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()) ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_public_id (public_id)
);

-- Define as funções (perfis) disponíveis no sistema (RBAC).
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(16) NOT NULL UNIQUE -- ex: 'ROLE_CUSTOMER', 'ROLE_PHARMACY_ADMIN'
);

-- Tabela de junção para atribuir funções aos usuários (Muitos-para-Muitos).
CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    role_id INT NOT NULL,
    FOREIGN KEY (role_id) REFERENCES roles(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    PRIMARY KEY (user_id, role_id)
);

-- =====================================================================
-- Seção 2: Entidades Centrais & Perfis
-- =====================================================================

-- Tabela de perfil para clientes.
CREATE TABLE IF NOT EXISTS customers (
    user_id BIGINT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
           
    full_name VARCHAR(255) NOT NULL,
    customer_type VARCHAR(16) NOT NULL,
    cpf VARCHAR(11) UNIQUE,
    cnpj VARCHAR(14) UNIQUE,
    birth_date DATE
);

-- Representa as entidades vendedoras (farmácias).
CREATE TABLE IF NOT EXISTS pharmacies (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    legal_name VARCHAR(64) NOT NULL UNIQUE,
    trade_name VARCHAR(64) NOT NULL,
    cnpj VARCHAR(14) NOT NULL UNIQUE,
    phone VARCHAR(11) NOT NULL,
    email VARCHAR(255),
    
    created_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP())
);

-- Tabela de perfil para funcionários de farmácias.
CREATE TABLE IF NOT EXISTS pharmacy_staff (
    user_id BIGINT PRIMARY KEY,
    FOREIGN KEY (user_id) REFERENCES users(id) 
	ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    pharmacy_id BIGINT NOT NULL,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) 
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    
    pharmacy_staff_position VARCHAR(16) NOT NULL
);

-- Tabela de perfil para entregadores.
CREATE TABLE IF NOT EXISTS delivery_personnel (
    user_id BIGINT PRIMARY KEY,
    cnh VARCHAR(11) NOT NULL UNIQUE, -- Carteira Nacional de Habilitação
    vehicle_details TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- =====================================================================
-- Seção 3: Catálogo de Produtos
-- =====================================================================

-- Tabela normalizada para marcas.
CREATE TABLE IF NOT EXISTS brands (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(64) NOT NULL UNIQUE
);

-- Tabela normalizada para fabricantes.
CREATE TABLE IF NOT EXISTS manufacturers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    manufacturer_name VARCHAR(64) NOT NULL UNIQUE
);

-- Informações abstratas do produto.
CREATE TABLE IF NOT EXISTS products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id BINARY(16) NOT NULL UNIQUE,
    product_name VARCHAR(128) NOT NULL,
    product_description VARCHAR(255),
    anvisa_code VARCHAR(20) UNIQUE,
    active_principle VARCHAR(255) NOT NULL,
    pharmaceutical_form VARCHAR(16),
    is_prescription_required BOOLEAN NOT NULL DEFAULT(FALSE),
    controlled_substance_list VARCHAR(10),
    
    brand_id BIGINT,
    FOREIGN KEY (brand_id) REFERENCES brands(id) 
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    
    manufacturer_id BIGINT,
	FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(id) 
	ON UPDATE CASCADE
	ON DELETE RESTRICT,
    
    created_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()),
    INDEX idx_public_id (public_id)
);

-- Variantes de produto específicas e vendáveis (SKUs).
CREATE TABLE IF NOT EXISTS product_variants (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    product_id BIGINT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    sku VARCHAR(100) NOT NULL UNIQUE,
    dosage VARCHAR(50),
    package_size VARCHAR(50),
    gtin VARCHAR(14) UNIQUE -- Código de barras
);

-- Categorias hierárquicas para organização de produtos.
CREATE TABLE IF NOT EXISTS categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    
    parent_id BIGINT,
    FOREIGN KEY (parent_id) REFERENCES categories(id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
);

-- Tabela de junção para produtos e categorias (Muitos-para-Muitos).
CREATE TABLE IF NOT EXISTS product_categories (
    product_id BIGINT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES products(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    category_id BIGINT NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    PRIMARY KEY (product_id, category_id)
);

-- =====================================================================
-- Seção 4: Inventário & Precificação
-- =====================================================================

-- Gerencia estoque e preço para cada variante de produto em cada farmácia.
CREATE TABLE IF NOT EXISTS inventory (
    pharmacy_id BIGINT NOT NULL,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    product_variant_id BIGINT NOT NULL,
    FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    price DECIMAL(10, 2) NOT NULL,
    quantity INT UNSIGNED NOT NULL DEFAULT 0,
    expiration_date DATE,
    updated_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()) ON UPDATE CURRENT_TIMESTAMP,
    
    PRIMARY KEY (pharmacy_id, product_variant_id),
    INDEX idx_product_variant_price (product_variant_id, price) -- Para consultas de comparação de preço
);

CREATE TABLE IF NOT EXISTS promotions (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    promotion_name VARCHAR(32) NOT NULL,
    discount_type VARCHAR(16) NOT NULL,
    discount_value DECIMAL(10, 2) NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    
    pharmacy_id BIGINT NOT NULL,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS promotion_rules (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    promotion_id BIGINT NOT NULL,
    FOREIGN KEY (promotion_id) REFERENCES promotions(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    rule_type VARCHAR(32) NOT NULL,
    rule_value DECIMAL(6,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS promotion_targets (
	id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    promotion_id BIGINT NOT NULL,
    FOREIGN KEY (promotion_id) REFERENCES promotions(id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    target_type VARCHAR(16) NOT NULL, -- O tipo de entidade ao qual a promoção se aplica. Ex.: PRODUCT CATEGORY BRAND ...
    target_id BIGINT NOT NULL
);

-- =====================================================================
-- Seção 5: Pedidos & Transações
-- =====================================================================

-- Informações de cabeçalho para pedidos de clientes.
CREATE TABLE IF NOT EXISTS orders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    public_id BINARY(16) NOT NULL UNIQUE,
    order_code VARCHAR(8),
    
    customer_id BIGINT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(user_id) 
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
    
    pharmacy_id BIGINT NOT NULL,
    FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) 
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
    
    order_status VARCHAR(16) NOT NULL,
    subtotal_amount DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    shipping_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()),
    updated_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()) ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_public_id (public_id)
);

-- Itens de linha para cada pedido.
CREATE TABLE IF NOT EXISTS order_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    order_id BIGINT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    product_variant_id BIGINT NOT NULL,
     FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) 
     ON UPDATE RESTRICT
     ON DELETE RESTRICT,
     
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL -- Preço no momento da compra
);

-- Armazena informações de receitas médicas enviadas.
CREATE TABLE IF NOT EXISTS prescriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    order_id BIGINT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) 
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
    
    prescription_code VARCHAR(32) NOT NULL UNIQUE,
    doctor_crm VARCHAR(20) NOT NULL,
    file_path VARCHAR(255),
    prescription_status VARCHAR(16) NOT NULL,
    
    validated_by BIGINT, -- user_id do pharmacy_staff
    FOREIGN KEY (validated_by) REFERENCES pharmacy_staff(user_id) 
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    
    validated_at TIMESTAMP
);

-- Registra transações de pagamento para os pedidos.
CREATE TABLE IF NOT EXISTS payments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    order_id BIGINT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) 
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(32) NOT NULL,
    payment_status VARCHAR(16) NOT NULL,
    transaction_id VARCHAR(255) UNIQUE, -- Do gateway de pagamento
    created_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP())
);

-- =====================================================================
-- Seção 6: Atendimento & Logística
-- =====================================================================

-- Tabela centralizada para todos os endereços.
CREATE TABLE IF NOT EXISTS addresses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    street VARCHAR(255) NOT NULL,
    complement VARCHAR(255),
    neighborhood VARCHAR(128) NOT NULL,
    city VARCHAR(64) NOT NULL,
    state VARCHAR(32) NOT NULL,
    postal_code VARCHAR(16) NOT NULL,
    country VARCHAR(32) NOT NULL
);

-- Tabela de junção ligando clientes a seus endereços.
CREATE TABLE IF NOT EXISTS customer_addresses (
    customer_id BIGINT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(user_id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    address_id BIGINT NOT NULL,
	FOREIGN KEY (address_id) REFERENCES addresses(id) 
    ON UPDATE CASCADE
    ON DELETE CASCADE,
    
    address_type VARCHAR(32) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT(FALSE),
    
    PRIMARY KEY (customer_id, address_id, address_type)
);

-- Gerencia o processo de entrega de um pedido.
CREATE TABLE IF NOT EXISTS deliveries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    
    order_id BIGINT NOT NULL UNIQUE,
    FOREIGN KEY (order_id) REFERENCES orders(id) 
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
    
    delivery_person_id BIGINT,
    FOREIGN KEY (delivery_person_id) REFERENCES delivery_personnel(user_id) 
    ON UPDATE CASCADE
    ON DELETE SET NULL,
    
    shipping_address_id BIGINT NOT NULL,
    FOREIGN KEY (shipping_address_id) REFERENCES addresses(id) 
    ON UPDATE RESTRICT
    ON DELETE RESTRICT,
    
    delivery_status VARCHAR(16) NOT NULL,
    estimated_delivery_date DATE,
    created_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()),
    updated_at TIMESTAMP NOT NULL DEFAULT(CURRENT_TIMESTAMP()) ON UPDATE CURRENT_TIMESTAMP
);