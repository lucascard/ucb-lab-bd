create database if not exists pharmacy_marketplace;

use pharmacy_marketplace;

create table if not exists users(
	id bigint primary key auto_increment,
  public_id binary(16) not null unique,
  email varchar(255) unique not null,
  user_password varchar(72) not null,
  phone_number varchar(11) unique,
  is_active tinyint(1) default(1),
  created_At timestamp default(current_timestamp()),
  updated_at timestamp default(current_timestamp()) on update current_timestamp
);

create table if not exists roles(
  id int primary key auto_increment,
  _name varchar(16) not null unique
);

create table if not exists user_roles(
  user_id bigint primary key,
    constraint fk_user_id
    foreign key (user_id) references users(id)
    on update cascade
    on delete restrict,

  role_id int primary key,
    constraint fk_role_id
    foreign key (role_id) references roles(id)
    on update cascade
    on delete restrict
);

create table if not exists customers(
	user_id bigint primary key,
	  constraint fk_user_id
    foreign key (user_id) references users(id)
    on update cascade
    on delete restrict,
    
  main_branch tinyint(1),
	full_name varchar(128) not null,
  customer_type varchar(16) not null,
  cpf varchar(11) unique,
  cnpj varchar(14) unique,
  birthday date
);

create table if not exists pharmacy_staff(
	user_id bigint primary key,
    constraint fk_user_id
    foreign key (user_id) references users(id)
    on update cascade
    on delete restrict,

  
);

create table if not exists pharmacies(
	id int primary key auto_increment,
  main_branch tinyint(1) not null,
  cnpj varchar(14) unique not null,
  legal_name varchar(128) unique not null,
  trade_name varchar(128) not null,
  email varchar(255) unique not null,
  phone varchar(11) unique not null
);

create table if not exists products(
	id int primary key auto_increment,
  product_name varchar(32) not null,
  product_descript varchar(255),
  brand varchar(16) not null,
  dosage varchar(8),
  validity_days varchar(8) not null,
  requires_prescription tinyint(1) not null,
  created_At date default(CURDATE())
);

create table if not exists stocks(
	id int primary key auto_increment,
  product_value decimal(10, 2) not null,
  quantity int,
    
  product_id int not null,
    constraint fk_product_id
    foreign key (product_id) references product(id)
    on update cascade
    on delete restrict,
    
  pharmacy_id int not null,
    constraint fk_pharmacy_id
    foreign key (pharmacy_id) references pharmacy(id)
    on update cascade
    on delete restrict
);

create table if not exists prescriptions(
	id int primary key auto_increment,
  content varchar(255) not null,
  prescription_code varchar(32) not null unique,
  doctor_crm varchar(16) not null,
  created_At date default(CURDATE())
);

create table if not exists orders(
	id int primary key auto_increment,
  order_code varchar(8) not null unique,
  order_status varchar(16) default 'pending',
  
  created_at timestamp default(current_timestamp()),
  updated_at  timestamp default(current_timestamp()) on update current_timestamp,
    
  customer_id int not null,
    constraint fk_orders_customer_id
    foreign key (customer_id) references customer(id)
    on update restrict
    on delete restrict,
	
  pharmacy_id int not null,
    constraint fk_orders_pharmacy_id
    foreign key (pharmacy_id) references pharmacy(id)
    on update restrict
    on delete restrict
);

create table if not exists item_orders(
	id int primary key auto_increment,
  quantity int not null,
    
  prescription_id int not null,
    constraint fk_prescription_id
    foreign key (prescription_id) references prescription(id)
    on update restrict
    on delete restrict,
    
  product_id int not null,
    constraint fk_product_id
    foreign key (product_id) references product(id)
    on update restrict
    on delete restrict,
    
	order_id int not null,
    constraint fk_orders_id
    foreign key (order_id) references orders(id)
    on update cascade
    on delete restrict
);

create table if not exists payments(
	id int primary key auto_increment,
  payment_type varchar(16) not null,
  payment_value decimal(10,2) not null,
  created_at timestamp default(current_timestamp())
);

create table if not exists order_payments(
	id int primary key auto_increment,
    
  payment_id int not null,
    constraint fk_payment_id
    foreign key (payment_id) references payment(id)
    on update cascade
    on delete restrict,
    
  order_id int not null,
    constraint fk_orders_id
    foreign key (order_id) references orders(id)
    on update cascade
    on delete restrict
);

create table if not exists delivery_mans(
	id int primary key auto_increment,
  cnh varchar(10) unique
);

create table if not exists vehicles(
	id int primary key auto_increment,
  license_plate varchar(7),
  brand varchar(32) not null,
  model varchar(32) not null,
  vehicle_year varchar(4) not null,
  color varchar(16) not null,
    
  delivery_man_id int not null,
    constraint fk_delivery_man_id
    foreign key (delivery_man_id) references delivery_man(id)
    on update cascade
    on delete restrict
);

create table if not exists addresses(
	id int primary key auto_increment,
  cep varchar(10) not null,
  place_references varchar(255) not null,
    
  -- Atributo composto 'ADDRESS' foi "achatado"
  street varchar(32) not null,
  neighborhood varchar(32) not null,
  city varchar(32) not null,
  complement varchar(128) not null,
  
  pharmacy_id int,
    constraint fk_pharmacy_id
    foreign key (pharmacy_id) references pharmacy(id)
    on update cascade
    on delete restrict,
  
  customer_id int,
    constraint fk_customer_id
    foreign key (customer_id) references customer(id)
    on update cascade
    on delete restrict,
    
  check(
		(pharmacy_id is not null and customer_id is null)
    or
    (pharmacy_id is null and customer_id is not null)
  )
);

create table if not exists deliveries(
	id int primary key auto_increment,
  delivery_cost decimal(6,2) not null,
  delivery_status varchar(16) default('awaiting_pickup'),
  created_at timestamp default(current_timestamp()),
  updated_at timestamp default(current_timestamp()) on update current_timestamp,
    
  delivery_man_id int not null,
    constraint fk_delivery_man_id
    foreign key (delivery_man_id) references delivery_man(id)
    on update cascade
    on delete restrict,
    
  order_id int unique not null,
    constraint fk_orders_id
    foreign key (order_id) references orders(id)
    on update cascade
    on delete restrict
);

create table if not exists rates(
	id int primary key auto_increment,
  evaluated_attribute varchar(16) not null,
  rating int not null,
  observation varchar(255),
    
  user_id int not null,
    constraint fk_user_id
    foreign key (user_id) references _user(id)
    on update cascade
    on delete restrict,
    
  delivery_id int,
    constraint fk_delivery_id
    foreign key (delivery_id) references delivery(id)
    on update cascade
    on delete restrict,
    
  product_id int,
    constraint fk_product_id
    foreign key (product_id) references product(id)
    on update cascade
    on delete restrict,
    
  check(
    (delivery_id is not null and product_id is null)
    or
    (delivery_id is null and product_id is not null)
    or
    (delivery_id is null and product_id is null)
  )
);
