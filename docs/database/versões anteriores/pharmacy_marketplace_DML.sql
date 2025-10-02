-- =================================================================================================
-- SCRIPT DE POPULAÇÃO DE DADOS (DATA SEEDING) - PHARMACY MARKETPLACE
-- =================================================================================================
-- OBJETIVO:
-- Este script realiza uma limpeza completa e repopulação massiva do banco de dados com um
-- conjunto de dados extremamente rico, diversificado e geograficamente expandido.
-- Ele foi projetado para ser um ambiente de teste e desenvolvimento robusto e final.

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
-- INÍCIO DA TRANSAÇÃO
-- -------------------------------------------------------------------------------------------------
START TRANSACTION;

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 1: DADOS FUNDAMENTAIS (LOOKUP TABLES)
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
-- SEÇÃO 2: ENTIDADES CENTRAIS (EXPANSÃO GEOGRÁFICA)
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
-- SEÇÃO 3: CATÁLOGO DE PRODUTOS E INVENTÁRIO (EXPANDIDO)
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
-- SEÇÃO 4: CARRINHOS DE COMPRAS ATIVOS (EXPANDIDO)
-- -------------------------------------------------------------------------------------------------
INSERT INTO `customer_cart_items` (`customer_id`, `product_variant_id`, `quantity`) VALUES
(1, 7, 1), (1, 6, 2), (6, 9, 3), (6, 10, 1);

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 5: SIMULAÇÃO DE FLUXOS DE NEGÓCIO (PEDIDOS EXPANDIDOS)
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
INSERT INTO `promotion_targets` (`promotion_id`, `target_type`, `target_id`) VALUES (2, 'PRODUCT', 7);
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
-- Pagamento nem chega a ser criado pois o fluxo foi barrado na validação.

-- -------------------------------------------------------------------------------------------------
-- SEÇÃO 6: ENGAJAMENTO (AVALIAÇÕES EXPANDIDAS)
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
-- SEÇÃO 7: GOVERNANÇA E CICLO DE VIDA DOS DADOS (EXPANDIDO)
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
-- CONCLUSÃO: FINALIZAÇÃO DA TRANSAÇÃO
-- -------------------------------------------------------------------------------------------------
COMMIT;

-- =================================================================================================
-- FIM DO SCRIPT DE POPULAÇÃO DE DADOS
-- =================================================================================================
