-- =====================================================================
-- Script DDL Completo para o Marketplace de Farmácia (Versão Refinada)
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
    INDEX idx_public_id (public_id)
);

-- Define as funções (perfis) disponíveis no sistema (RBAC).
CREATE TABLE IF NOT EXISTS roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE -- Ex: 'ROLE_CUSTOMER', 'ROLE_PHARMACY_ADMIN'
);

-- Tabela de junção para atribuir funções aos usuários (Muitos-para-Muitos).
CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id INT NOT NULL,
    
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_user_roles_roles FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE ON UPDATE NO ACTION
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
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
);

-- Tabela de perfil para funcionários de farmácias.
CREATE TABLE IF NOT EXISTS pharmacy_staff (
    user_id BIGINT PRIMARY KEY,
    pharmacy_id BIGINT NOT NULL,
    position VARCHAR(100) NOT NULL,
    
    CONSTRAINT fk_pharmacy_staff_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_pharmacy_staff_pharmacies FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE RESTRICT ON UPDATE NO ACTION
);

-- Tabela de perfil para entregadores.
CREATE TABLE IF NOT EXISTS delivery_personnel (
    user_id BIGINT PRIMARY KEY,
    cnh VARCHAR(11) NOT NULL UNIQUE,
    vehicle_details TEXT,
    
    CONSTRAINT fk_delivery_personnel_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- =====================================================================
-- Seção 3: Catálogo de Produtos
-- =====================================================================

-- Tabela para as marcas dos produtos
CREATE TABLE IF NOT EXISTS brands (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Tabela para os fabricantes dos produtos
CREATE TABLE IF NOT EXISTS manufacturers (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
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
    controlled_substance_list VARCHAR(10),
    brand_id BIGINT,
    manufacturer_id BIGINT,
    created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    
    INDEX idx_public_id (public_id),
    CONSTRAINT fk_products_brands FOREIGN KEY (brand_id) REFERENCES brands(id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_products_manufacturers FOREIGN KEY (manufacturer_id) REFERENCES manufacturers(id) ON DELETE RESTRICT ON UPDATE NO ACTION
);

-- Tabela para cadastro dos produtos das farmacias e seus variantes
CREATE TABLE IF NOT EXISTS product_variants (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    dosage VARCHAR(50),
    package_size VARCHAR(50),
    gtin VARCHAR(14) UNIQUE,
    
    CONSTRAINT fk_product_variants_products FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE NO ACTION
);

-- Tabela para categoria dos produtos
CREATE TABLE IF NOT EXISTS categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    parent_id BIGINT,
    
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL ON UPDATE NO ACTION
);

-- Tabela que vincula os produtos com sua categoria
CREATE TABLE IF NOT EXISTS product_categories (
    product_id BIGINT NOT NULL,
    category_id BIGINT NOT NULL,
    
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_product_categories_products FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_product_categories_categories FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE ON UPDATE NO ACTION
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
    INDEX idx_product_variant_price (product_variant_id, price),
    CONSTRAINT fk_inventory_pharmacies FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE CASCADE ON UPDATE NO ACTION,
    CONSTRAINT fk_inventory_product_variants FOREIGN KEY (product_variant_id) REFERENCES product_variants(id) ON DELETE CASCADE ON UPDATE NO ACTION
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
    
    INDEX idx_public_id (public_id),
    CONSTRAINT fk_orders_customers FOREIGN KEY (customer_id) REFERENCES customers(user_id) ON DELETE RESTRICT ON UPDATE NO ACTION,
    CONSTRAINT fk_orders_pharmacies FOREIGN KEY (pharmacy_id) REFERENCES pharmacies(id) ON DELETE RESTRICT ON UPDATE NO ACTION
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