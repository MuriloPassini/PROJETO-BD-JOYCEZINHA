CREATE DATABASE IF NOT EXISTS clinica_passini;
USE clinica_passini;

-- tabela de usuários
CREATE TABLE usuario (
id_usuario INT AUTO_INCREMENT PRIMARY KEY,
user_hash VARCHAR(50) NOT NULL,
password_hash VARCHAR(50) NOT NULL
);

-- tabela de todos os convênios que os médicos da clínas atendem
CREATE TABLE convenios(
id_convenio INT AUTO_INCREMENT PRIMARY KEY,
nome_convenio VARCHAR(50) NOT NULL
);

-- tabela dos profissionais
CREATE TABLE profissionais(
id_profissional INT AUTO_INCREMENT PRIMARY KEY,
nome_profissional VARCHAR(100) NOT NULL,
sobrenome_profissional VARCHAR(100) NOT NULL,
nome_social_profissional VARCHAR(100),
cpf_profissional VARCHAR(11) UNIQUE NOT NULL,
cro VARCHAR(20) UNIQUE NOT NULL,
email_profissional VARCHAR(100) UNIQUE NOT NULL,
telefone_profissional VARCHAR(18) UNIQUE NOT NULL,
pix VARCHAR(50) NOT NULL,
status BOOLEAN DEFAULT TRUE 
);

-- tabela para referenciar o profissional e o convênio que ele atende
CREATE TABLE profissionais_convenio(
id_vinculo INT AUTO_INCREMENT PRIMARY KEY,
id_profissional INT NOT NULL,
id_convenio INT NOT NULL,
FOREIGN KEY (id_profissional) REFERENCES profissionais(id_profissional),
FOREIGN KEY (id_convenio) REFERENCES convenios(id_convenio)
);

-- tabela de todos os serviços que é feito na clínica
CREATE TABLE servicos (
id_servico INT AUTO_INCREMENT PRIMARY KEY,
nome_servico VARCHAR(70),
descricao_servico VARCHAR(150),
preco_servico DECIMAL(5,2)
);

-- tabela para relacionar os profissionais e o serviço que eles fazem
CREATE TABLE especialidadeXprofissional(
id_especialidade INT AUTO_INCREMENT PRIMARY KEY,
id_profissional INT NOT NULL,
id_servico INT NOT NULL,

FOREIGN KEY (id_profissional)
REFERENCES profissionais(id_profissional),

FOREIGN KEY (id_servico)
REFERENCES servicos(id_servico)
);

-- tabela dos clientes
CREATE TABLE clientes(
id_cliente INT AUTO_INCREMENT PRIMARY KEY,
nome_cliente VARCHAR(100) NOT NULL,
sobrenome_cliente VARCHAR(100) NOT NULL,
nome_social_cliente VARCHAR(100),
telefone_cliente VARCHAR(50) NOT NULL,
cpf_cliente VARCHAR(11) UNIQUE NOT NULL,
id_convenio INT,
termo_servico BOOLEAN NOT NULL,
FOREIGN KEY (id_convenio) REFERENCES convenios(id_convenio)
);

-- tabela de agendamento das consultas
CREATE TABLE agenda(
id_consulta INT AUTO_INCREMENT PRIMARY KEY,
data_consulta DATETIME,
id_cliente INT NOT NULL,
id_profissional INT NOT NULL,
FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
FOREIGN KEY (id_profissional) REFERENCES profissionais(id_profissional)
);

-- Tabela principal do pagamento 
CREATE TABLE pagamentos (
    id_pagamento     INT AUTO_INCREMENT PRIMARY KEY,
    id_consulta      INT NOT NULL,
    id_cliente       INT NOT NULL,
    valor_total      DECIMAL(10,2) NOT NULL,
    data_pagamento   DATE NOT NULL,
    forma_pagamento  ENUM('dinheiro', 'cartao_credito', 'cartao_debito', 'pix', 'boleto') NOT NULL,
    status           ENUM('pago', 'pendente', 'parcelado') NOT NULL DEFAULT 'pendente',
    observacao       VARCHAR(255),
    criado_em        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_consulta) REFERENCES agenda(id_consulta),
    FOREIGN KEY (id_cliente)  REFERENCES clientes(id_cliente)
);

-- Detalhamento dos serviços realizados em cada pagamento
CREATE TABLE pagamento_servicos (
    id_item          INT AUTO_INCREMENT PRIMARY KEY,
    id_pagamento     INT NOT NULL,
    id_servico       INT NOT NULL,
    valor_cobrado    DECIMAL(10,2)  NOT NULL, -- pode diferir do preco_servico (desconto, convênio, etc)

    FOREIGN KEY (id_pagamento) REFERENCES pagamentos(id_pagamento),
    FOREIGN KEY (id_servico)   REFERENCES servicos(id_servico)
);

-- Registra toda alteração feita em qualquer tabela importante
CREATE TABLE auditoria_log (
    id_log          INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario      INT NULL,                  
    tabela          VARCHAR(60) NOT NULL,          
    operacao        ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    id_registro     INT NOT NULL,                
    dados_antes     JSON NULL,                   
    dados_depois    JSON NULL,                   
    data_acao       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_origem       VARCHAR(45)NULL,

    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);
-- Rastreia quem acessou o sistema e quando
CREATE TABLE auditoria_acesso (
    id_acesso       INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario      INT NOT NULL,
    tipo            ENUM('login', 'logout', 'login_falhou') NOT NULL,
    data_acesso     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_origem       VARCHAR(45) NULL,
    dispositivo     VARCHAR(100) NULL,

    FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
);


-- LGPD