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

-- =====================
-- Blocos de DML (inserções)
-- =====================

-- =====================================================================
-- Script DML para População e Manipulação do Banco 'pharmacy_marketplace'
-- =====================================================================
-- Este script insere dados de exemplo realistas para simular um
-- ambiente de produção, cobrindo todas as entidades do sistema.
-- Também inclui exemplos de consultas (SELECT) e atualizações (UPDATE).
-- =====================================================================

USE pharmacy_marketplace;

-- =====================================================================
-- Seção 1: Inserção em Tabelas de Lookup e Controle de Acesso
-- =====================================================================

-- Inserindo Funções (Roles)
INSERT INTO `roles` (`id`, `name`) VALUES
(1, 'ROLE_CUSTOMER'),
(2, 'ROLE_PHARMACY_ADMIN'),
(3, 'ROLE_PHARMACY_STAFF'),
(4, 'ROLE_DELIVERY_PERSONNEL'),
(5, 'ROLE_SYSTEM_ADMIN');

-- Inserindo Marcas (Brands)
INSERT INTO `brands` (`name`) VALUES
('Medley'),
('EMS'),
('Neo Química'),
('Aché'),
('Eurofarma'),
('Hypera Pharma'),
('Johnson & Johnson'),
('Colgate-Palmolive'),
('Nivea'),
('Sanofi');

-- Inserindo Fabricantes (Manufacturers)
INSERT INTO `manufacturers` (`name`) VALUES
('Medley Indústria Farmacêutica'),
('EMS S.A.'),
('Brainfarma Indústria Química e Farmacêutica S.A.'),
('Aché Laboratórios Farmacêuticos S.A.'),
('Eurofarma Laboratórios S.A.'),
('Hypera S.A.'),
('Johnson & Johnson do Brasil'),
('Colgate-Palmolive do Brasil'),
('Beiersdorf Ind. e Com. Ltda'),
('Sanofi-Aventis Farmacêutica Ltda');

-- Inserindo Categorias (Hierárquicas)
INSERT INTO `categories` (`id`, `name`, `parent_id`) VALUES
(1, 'Medicamentos', NULL),
(2, 'Higiene Pessoal', NULL),
(3, 'Vitaminas e Suplementos', NULL),
(4, 'Analgésicos e Antitérmicos', 1),
(5, 'Anti-inflamatórios', 1),
(6, 'Higiene Bucal', 2),
(7, 'Cuidados com a Pele', 2),
(8, 'Vitaminas de A-Z', 3);


-- =====================================================================
-- Seção 2: Inserção de Entidades Principais (Usuários, Farmácias, Produtos)
-- =====================================================================

-- Inserindo Usuários (Senhas são placeholders, devem ser hashes bcrypt)
INSERT INTO `users` (`public_id`, `email`, `hashed_password`, `phone_number`, `is_active`) VALUES
(UUID_TO_BIN(UUID()), 'ana.silva@email.com', '$2a$10$...', '11987654321', TRUE), -- Cliente
(UUID_TO_BIN(UUID()), 'bruno.costa@email.com', '$2a$10$...', '21912345678', TRUE), -- Cliente Jurídico
(UUID_TO_BIN(UUID()), 'carlos.gerente@farmabem.com', '$2a$10$...', '11999998888', TRUE), -- Admin Farmácia
(UUID_TO_BIN(UUID()), 'daniela.atendente@farmabem.com', '$2a$10$...', '11977776666', TRUE), -- Staff Farmácia
(UUID_TO_BIN(UUID()), 'eduardo.entregador@loggi.com', '$2a$10$...', '11966665555', TRUE), -- Entregador
(UUID_TO_BIN(UUID()), 'fernanda.gerente@drogasaude.com', '$2a$10$...', '85988887777', TRUE), -- Admin outra Farmácia
(UUID_TO_BIN(UUID()), 'gisele.cliente@email.com', '$2a$10$...', '48955554444', TRUE); -- Cliente

-- Inserindo Farmácias
INSERT INTO `pharmacies` (`legal_name`, `trade_name`, `cnpj`, `phone`, `email`) VALUES
('FarmaBem Matriz Ltda', 'FarmaBem - Centro', '11222333000144', '1140028922', 'contato@farmabem.com'),
('FarmaBem Filial Paulista Ltda', 'FarmaBem - Paulista', '11222333000225', '1130304040', 'paulista@farmabem.com'),
('DrogaSaúde Ceará Medicamentos', 'DrogaSaúde', '44555666000177', '8532001010', 'contato@drogasaude.com.br');

-- Inserindo Produtos Abstratos
INSERT INTO `products` (`public_id`, `name`, `description`, `anvisa_code`, `active_principle`, `pharmaceutical_form`, `is_prescription_required`, `brand_id`, `manufacturer_id`) VALUES
(UUID_TO_BIN(UUID()), 'Dipirona Monoidratada 500mg', 'Analgésico e antitérmico.', '1832602160021', 'Dipirona Monoidratada', 'Comprimido', FALSE, 1, 1),
(UUID_TO_BIN(UUID()), 'Paracetamol 750mg', 'Indicado para o alívio temporário de dores leves a moderadas.', '1781708300051', 'Paracetamol', 'Comprimido', FALSE, 2, 2),
(UUID_TO_BIN(UUID()), 'Nimesulida 100mg', 'Ação anti-inflamatória, analgésica e antitérmica.', '1023506720015', 'Nimesulida', 'Comprimido', TRUE, 3, 3),
(UUID_TO_BIN(UUID()), 'Creme Dental Colgate Total 12', 'Proteção completa para uma boca mais saudável.', NULL, 'Fluoreto de Sódio, Triclosan', 'Creme Dental', FALSE, 8, 8),
(UUID_TO_BIN(UUID()), 'Protetor Solar Nivea Sun Protect & Hidrata FPS 50', 'Alta proteção contra raios UVA/UVB.', NULL, 'Octocrileno, Avobenzona', 'Loção', FALSE, 9, 9),
(UUID_TO_BIN(UUID()), 'Losartana Potássica 50mg', 'Tratamento da hipertensão.', '1004309940029', 'Losartana Potássica', 'Comprimido Revestido', TRUE, 4, 4),
(UUID_TO_BIN(UUID()), 'Shampoo Anticaspa Clear Men', 'Limpeza profunda e alívio da coceira.', NULL, 'Piritionato de Zinco', 'Shampoo', FALSE, 7, 7);

-- Inserindo Relações Produto-Categoria
INSERT INTO `product_categories` (`product_id`, `category_id`) VALUES
(1, 1), (1, 4),
(2, 1), (2, 4),
(3, 1), (3, 5),
(4, 2), (4, 6),
(5, 2), (5, 7),
(6, 1),
(7, 2);

-- Inserindo Variantes de Produto (SKUs)
INSERT INTO `product_variants` (`product_id`, `sku`, `dosage`, `package_size`, `gtin`) VALUES
(1, 'MED-DIP500-10CP', '500mg', '10 Comprimidos', '7896422506015'),
(1, 'MED-DIP500-30CP', '500mg', '30 Comprimidos', '7896422506022'),
(2, 'EMS-PAR750-20CP', '750mg', '20 Comprimidos', '7896004709831'),
(3, 'NEO-NIM100-12CP', '100mg', '12 Comprimidos', '7896714211045'),
(4, 'COL-TOT12-90G', NULL, '90g', '7891024134708'),
(5, 'NIV-SUN50-200ML', 'FPS 50', '200ml', '7891177215234'),
(6, 'ACH-LOS50-30CP', '50mg', '30 Comprimidos', '7896658006451'),
(7, 'CLE-SHAMP-400ML', NULL, '400ml', '7891150012345');

-- >>> CORREÇÃO ADICIONADA: inserir explicitamente uma variante (id = 8)
-- para resolver referências a product_variant_id = 8 que existiam no DML (inventory / order_items).
-- Isto preserva o conteúdo original enquanto corrige a integridade referencial.
INSERT INTO product_variants (id, product_id, sku, dosage, package_size, gtin) VALUES
(8, 7, 'CLE-SHAMP-400ML-2', NULL, '400ml', '7891150012346');
-- <<< fim da correção automática



-- =====================================================================
-- Seção 3: Inserção de Perfis e Relações de Usuários
-- =====================================================================

-- Atribuindo Funções aos Usuários
INSERT INTO `user_roles` (`user_id`, `role_id`) VALUES
(1, 1), -- Ana é cliente
(2, 1), -- Bruno é cliente
(3, 2), -- Carlos é admin da farmabem
(4, 3), -- Daniela é staff da farmabem
(5, 4), -- Eduardo é entregador
(6, 2), -- Fernanda é admin da drogasaude
(7, 1); -- Gisele é cliente

-- Criando Perfis de Clientes
INSERT INTO `customers` (`user_id`, `full_name`, `customer_type`, `cpf`, `cnpj`, `birth_date`) VALUES
(1, 'Ana Clara Silva', 'INDIVIDUAL', '11122233344', NULL, '1990-05-15'),
(2, 'Costa & Filhos Comércio LTDA', 'LEGAL_ENTITY', NULL, '55666777000188', NULL),
(7, 'Gisele Santos', 'INDIVIDUAL', '44455566677', NULL, '1985-11-20');

-- Criando Perfis de Funcionários de Farmácia
INSERT INTO `pharmacy_staff` (`user_id`, `pharmacy_id`, `position`) VALUES
(3, 1, 'Gerente Geral'), -- Carlos gerencia a matriz da FarmaBem
(4, 2, 'Atendente'), -- Daniela trabalha na filial da FarmaBem
(6, 3, 'Farmacêutica Responsável'); -- Fernanda gerencia a DrogaSaúde

-- Criando Perfil de Entregador
INSERT INTO `delivery_personnel` (`user_id`, `cnh`, `vehicle_details`) VALUES
(5, '12345678901', 'Moto Honda CG 160, Placa ABC1D23');


-- =====================================================================
-- Seção 4: Inserção de Inventário, Preços e Endereços
-- =====================================================================

-- Inserindo Inventário (Preços e Quantidades por farmácia)
-- FarmaBem Matriz (ID 1)
INSERT INTO `inventory` (`pharmacy_id`, `product_variant_id`, `price`, `quantity`, `expiration_date`) VALUES
(1, 1, 4.50, 100, '2026-10-01'),
(1, 2, 12.00, 50, '2026-10-01'),
(1, 3, 9.80, 80, '2025-12-01'),
(1, 4, 19.90, 30, '2027-01-01'),
(1, 5, 3.99, 150, '2026-08-01'),
(1, 7, 25.50, 40, '2026-05-01');

-- DrogaSaúde (ID 3)
INSERT INTO `inventory` (`pharmacy_id`, `product_variant_id`, `price`, `quantity`, `expiration_date`) VALUES
(3, 1, 4.75, 200, '2026-11-01'),
(3, 3, 10.50, 120, '2025-11-01'),
(3, 5, 3.89, 300, '2026-09-01'),
(3, 6, 52.50, 60, '2027-02-01'),
(3, 8, 18.90, 90, '2026-07-01');

-- Inserindo Endereços
INSERT INTO `addresses` (`id`, `street`, `complement`, `neighborhood`, `city`, `state`, `postal_code`) VALUES
(101, 'Rua das Flores, 123', 'Apto 45', 'Centro', 'São Paulo', 'SP', '01000-001'), -- Ana
(102, 'Avenida Principal, 987', 'Sala 201', 'Comercial', 'Rio de Janeiro', 'RJ', '20000-002'), -- Bruno
(103, 'Praça da Sé, 100', NULL, 'Centro', 'São Paulo', 'SP', '01001-000'), -- FarmaBem Matriz
(104, 'Avenida Paulista, 1500', 'Loja 3', 'Bela Vista', 'São Paulo', 'SP', '01310-200'), -- FarmaBem Filial
(105, 'Avenida Beira Mar, 3000', NULL, 'Meireles', 'Fortaleza', 'CE', '60165-121'), -- DrogaSaúde
(106, 'Rua dos Girassóis, 456', 'Casa', 'Jardins', 'Florianópolis', 'SC', '88000-123'); -- Gisele

-- Associando Endereços aos Clientes
INSERT INTO `customer_addresses` (`customer_id`, `address_id`, `address_type`, `is_default`) VALUES
(1, 101, 'SHIPPING', TRUE),
(1, 101, 'BILLING', TRUE),
(2, 102, 'SHIPPING', TRUE),
(7, 106, 'SHIPPING', TRUE);

-- Associando Endereços às Farmácias
INSERT INTO `pharmacy_locations` (`pharmacy_id`, `address_id`, `is_headquarters`) VALUES
(1, 103, TRUE), -- Matriz FarmaBem
(2, 104, FALSE), -- Filial FarmaBem
(3, 105, TRUE);  -- Matriz DrogaSaúde

-- =====================================================================
-- Seção 5: Simulação de Transações (Pedidos, Pagamentos, Entregas)
-- =====================================================================

-- Pedido 1: Ana compra um analgésico na FarmaBem Matriz (Status Entregue)
INSERT INTO `orders` (`public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `discount_amount`, `shipping_amount`, `total_amount`) VALUES
(UUID_TO_BIN(UUID()), 'AB12CD34', 1, 1, 'DELIVERED', 12.00, 0.00, 5.00, 17.00);
SET @last_order_id_1 = LAST_INSERT_ID();

INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES
(@last_order_id_1, 2, 1, 12.00); -- 1 caixa de Dipirona com 30cp

INSERT INTO `payments` (`order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES
(@last_order_id_1, 17.00, 'CREDIT_CARD', 'SUCCESSFUL', 'pi_123abc456def');

INSERT INTO `deliveries` (`order_id`, `delivery_person_id`, `shipping_address_id`, `delivery_status`, `estimated_delivery_date`) VALUES
(@last_order_id_1, 5, 101, 'DELIVERED', '2025-09-28');

-- Pedido 2: Gisele compra um anti-inflamatório na DrogaSaúde (Aguardando Receita)
INSERT INTO `orders` (`public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `discount_amount`, `shipping_amount`, `total_amount`) VALUES
(UUID_TO_BIN(UUID()), 'EF56GH78', 7, 3, 'AWAITING_PRESCRIPTION', 10.50, 0.00, 8.00, 18.50);
SET @last_order_id_2 = LAST_INSERT_ID();

INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES
(@last_order_id_2, 4, 1, 10.50); -- 1 caixa de Nimesulida

INSERT INTO `prescriptions` (`order_id`, `prescription_code`, `doctor_crm`, `file_path`, `status`) VALUES
(@last_order_id_2, 'REC2025XYZ', '123456-SP', '/uploads/prescriptions/rec2025xyz.pdf', 'PENDING_VALIDATION');

-- Pedido 3: Ana compra protetor solar e shampoo (Processando)
INSERT INTO `orders` (`public_id`, `order_code`, `customer_id`, `pharmacy_id`, `order_status`, `subtotal_amount`, `discount_amount`, `shipping_amount`, `total_amount`) VALUES
(UUID_TO_BIN(UUID()), 'IJ90KL12', 1, 1, 'PROCESSING', 45.40, 0.00, 5.00, 50.40);
SET @last_order_id_3 = LAST_INSERT_ID();

INSERT INTO `order_items` (`order_id`, `product_variant_id`, `quantity`, `unit_price`) VALUES
(@last_order_id_3, 6, 1, 19.90), -- 1 Protetor Nivea
(@last_order_id_3, 8, 1, 25.50); -- 1 Shampoo Clear

INSERT INTO `payments` (`order_id`, `amount`, `payment_method`, `status`, `transaction_id`) VALUES
(@last_order_id_3, 50.40, 'PIX', 'SUCCESSFUL', 'pix_txid_987zyx654');


-- =====================================================================
-- Seção 6: Exemplos de Consultas (SELECT)
-- =====================================================================

-- 1. Consultar todos os produtos disponíveis na "FarmaBem - Matriz" (ID 1), com preço e quantidade.
SELECT 
    p.name AS produto,
    pv.package_size AS embalagem,
    i.price AS preco,
    i.quantity AS estoque
FROM inventory i
JOIN product_variants pv ON i.product_variant_id = pv.id
JOIN products p ON pv.product_id = p.id
WHERE i.pharmacy_id = 1;

-- 2. Consultar os detalhes de um pedido específico (Pedido da Ana, ID = @last_order_id_1).
SELECT
    o.id AS pedido_id,
    o.order_code AS codigo_pedido,
    c.full_name AS cliente,
    ph.trade_name AS farmacia,
    o.order_status AS status_pedido,
    o.total_amount AS valor_total,
    d.delivery_status AS status_entrega
FROM orders o
JOIN customers c ON o.customer_id = c.user_id
JOIN pharmacies ph ON o.pharmacy_id = ph.id
LEFT JOIN deliveries d ON o.id = d.order_id
WHERE o.id = @last_order_id_1;

-- 3. Listar todos os pedidos que necessitam de validação de receita.
SELECT
    o.id AS pedido_id,
    c.full_name AS cliente,
    p.prescription_code AS codigo_receita,
    p.status AS status_receita,
    o.created_at AS data_pedido
FROM prescriptions p
JOIN orders o ON p.order_id = o.id
JOIN customers c ON o.customer_id = c.user_id
WHERE p.status = 'PENDING_VALIDATION';

-- 4. Encontrar todos os analgésicos e antitérmicos (Categoria ID 4) e ordená-los por preço.
SELECT 
    p.name,
    b.name AS brand,
    ph.trade_name AS pharmacy,
    i.price
FROM inventory i
JOIN product_variants pv ON i.product_variant_id = pv.id
JOIN products p ON pv.product_id = p.id
JOIN brands b ON p.brand_id = b.id
JOIN pharmacies ph ON i.pharmacy_id = ph.id
JOIN product_categories pc ON p.id = pc.product_id
WHERE pc.category_id = 4 AND i.quantity > 0
ORDER BY i.price ASC;


-- =====================================================================
-- Seção 7: Exemplos de Atualizações (UPDATE)
-- =====================================================================

-- 1. Simular a venda de um item: Atualizar o estoque de Dipirona (variant_id 2) na FarmaBem (pharmacy_id 1)
-- Supondo que o pedido @last_order_id_1 acaba de ser processado.
UPDATE inventory
SET quantity = quantity - 1
WHERE pharmacy_id = 1 AND product_variant_id = 2;

-- 2. Atualizar o status de um pedido para "Enviado" (SHIPPED).
UPDATE orders
SET order_status = 'SHIPPED'
WHERE id = @last_order_id_3;

-- 3. Validar uma receita médica. (A farmacêutica Fernanda, user_id 6, validou a receita do pedido 2)
UPDATE prescriptions
SET 
    status = 'VALIDATED',
    validated_by = 6,
    validated_at = CURRENT_TIMESTAMP(6)
WHERE order_id = @last_order_id_2;

-- Consequentemente, o status do pedido também deve ser atualizado.
UPDATE orders
SET order_status = 'PROCESSING' -- ou 'AWAITING_PAYMENT' se o fluxo exigir
WHERE id = @last_order_id_2;

-- 4. Desativar um usuário em vez de deletá-lo (Soft Delete).
UPDATE users
SET is_active = FALSE
WHERE email = 'gisele.cliente@email.com';
