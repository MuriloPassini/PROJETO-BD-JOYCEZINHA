CREATE DATABASE IF NOT EXISTS clinica_passini;
USE clinica_passini;

-- tabela de todos os convênios que os médicos da clínas atendem
CREATE TABLE convenios(
id_convenio INT AUTO_INCREMENT PRIMARY KEY,
nome_convenio VARCHAR(50) NOT NULL UNIQUE
);

-- tabela dos clientes
CREATE TABLE clientes(
id_cliente INT AUTO_INCREMENT PRIMARY KEY,
nome_cliente VARCHAR(100) NOT NULL,
sobrenome_cliente VARCHAR(100) NOT NULL,
nome_social_cliente VARCHAR(100),
telefone_cliente VARCHAR(50) NOT NULL,
email_cliente VARCHAR(100) UNIQUE,
cpf_cliente_hash VARCHAR(11) UNIQUE NOT NULL,
id_convenio INT,
termo_servico BOOLEAN NOT NULL DEFAULT FALSE,
FOREIGN KEY (id_convenio) REFERENCES convenios(id_convenio)
);

-- tabela dos profissionais
CREATE TABLE profissionais(
id_profissional INT AUTO_INCREMENT PRIMARY KEY,
nome_profissional VARCHAR(100) NOT NULL,
sobrenome_profissional VARCHAR(100) NOT NULL,
nome_social_profissional VARCHAR(100),
cpf_profissional_hash VARCHAR(11) UNIQUE NOT NULL,
cro VARCHAR(20) UNIQUE NOT NULL,
email_profissional VARCHAR(100) UNIQUE NOT NULL,
telefone_profissional VARCHAR(18) UNIQUE NOT NULL,
pix VARCHAR(50) NOT NULL,
status BOOLEAN DEFAULT TRUE 
);

-- tabela de usuários
CREATE TABLE usuario (
id_usuario INT AUTO_INCREMENT PRIMARY KEY,
user_hash VARCHAR(50) NOT NULL,
password_hash VARCHAR(50) NOT NULL,
acesso ENUM('admin', 'recepcionista', 'profissional', 'cliente') NOT NULL DEFAULT 'cliente',
id_profissional INT,
id_cliente INT,
FOREIGN KEY (id_profissional) REFERENCES profissionais(id_profissional),
FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
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
nome_servico VARCHAR(70) NOT NULL,
descricao_servico VARCHAR(150) NOT NULL,
preco_servico DECIMAL(7,2)
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

-- tabela de agendamento das consultas
CREATE TABLE agenda(
id_consulta INT AUTO_INCREMENT PRIMARY KEY,
data_consulta DATETIME NOT NULL,
id_cliente INT NOT NULL,
id_profissional INT NOT NULL,
status ENUM('agendada', 'realizada', 'cancelada') DEFAULT 'agendada',
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

-- procedures
	-- convênios
DELIMITER $$
CREATE PROCEDURE cadastrar_covenio(
	IN p_nome VARCHAR(50)
)
BEGIN
	INSERT INTO convenios (nome_convenio) VALUES (p_nome);
END $$

DELIMITER $$
CREATE PROCEDURE deletar_convenio(
	IN p_id VARCHAR(50)
)
BEGIN
	DELETE FROM convenios WHERE id_convenio = p_id;
END $$

	-- profissionais
CREATE PROCEDURE cadastrar_profissional(
    IN p_nome VARCHAR(100),
    IN p_sobrenome VARCHAR(100),
    IN p_nome_social VARCHAR(100),
    IN p_cpf VARCHAR(11),
    IN p_cro VARCHAR(20),
    IN p_email VARCHAR(100),
    IN p_telefone VARCHAR(18),
    IN p_pix VARCHAR(50)
)
BEGIN
    INSERT INTO profissionais (
        nome_profissional,
        sobrenome_profissional,
        nome_social_profissional,
        cpf_profissional_hash,
        cro,
        email_profissional,
        telefone_profissional,
        pix
    )
    VALUES (
        p_nome, p_sobrenome, p_nome_social,
        p_cpf, p_cro, p_email, p_telefone, p_pix
    );
END$$
 
CREATE PROCEDURE editar_profissional(
    IN p_id INT,
    IN p_nome VARCHAR(100),
    IN p_sobrenome VARCHAR(100),
    IN p_email VARCHAR(100),
    IN p_telefone VARCHAR(18),
    IN p_pix VARCHAR(50)
)
BEGIN
    UPDATE profissionais
    SET
        nome_profissional = p_nome,
        sobrenome_profissional = p_sobrenome,
        email_profissional = p_email,
        telefone_profissional = p_telefone,
        pix = p_pix
    WHERE id_profissional = p_id;
END$$

CREATE PROCEDURE remover_profissional(
    IN p_id INT
)
BEGIN
    UPDATE profissionais
    SET status = FALSE
    WHERE id_profissional = p_id;
END$$

CREATE PROCEDURE vincular_convenio_profissional(
    IN p_id_profissional INT,
    IN p_id_convenio INT
)
BEGIN
    INSERT INTO profissionais_convenio (id_profissional, id_convenio)
    VALUES (p_id_profissional, p_id_convenio);
END$$
 
CREATE PROCEDURE vincular_servico_profissional(
    IN p_id_profissional INT,
    IN p_id_servico INT
)
BEGIN
    INSERT INTO especialidadeXprofissional (id_profissional, id_servico)
    VALUES (p_id_profissional, p_id_servico);
END$$
    
    -- clientes
CREATE PROCEDURE cadastrar_cliente(
    IN p_nome VARCHAR(100),
    IN p_sobrenome VARCHAR(100),
    IN p_nome_social VARCHAR(100),
    IN p_telefone VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_cpf VARCHAR(11),
    IN p_id_convenio INT,
    IN p_termo BOOLEAN
)
BEGIN
    INSERT INTO clientes (
        nome_cliente,
        sobrenome_cliente,
        nome_social_cliente,
        telefone_cliente,
        email_cliente,
        cpf_cliente_hash,
        id_convenio,
        termo_servico
    )
    VALUES (
        p_nome, p_sobrenome, p_nome_social,
        p_telefone, p_email, p_cpf,
        p_id_convenio, p_termo
    );
END$$
 
CREATE PROCEDURE editar_cliente(
    IN p_id INT,
    IN p_nome VARCHAR(100),
    IN p_sobrenome VARCHAR(100),
    IN p_telefone VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_id_convenio INT
)
BEGIN
    UPDATE clientes
    SET
        nome_cliente = p_nome,
        sobrenome_cliente = p_sobrenome,
        telefone_cliente = p_telefone,
        email_cliente = p_email,
        id_convenio = p_id_convenio
    WHERE id_cliente = p_id;
END$$
    
CREATE PROCEDURE remover_cliente(
    IN p_id INT
)
BEGIN
    UPDATE clientes
    SET termo_servico = FALSE
    WHERE id_cliente = p_id;
END$$

	-- serviços
CREATE PROCEDURE cadastrar_servico(
    IN p_nome VARCHAR(70),
    IN p_descricao VARCHAR(150),
    IN p_preco DECIMAL(7,2)
)
BEGIN
    INSERT INTO servicos (nome_servico, descricao_servico, preco_servico)
    VALUES (p_nome, p_descricao, p_preco);
END$$
 
CREATE PROCEDURE editar_servico(
    IN p_id INT,
    IN p_nome VARCHAR(70),
    IN p_descricao VARCHAR(150),
    IN p_preco DECIMAL(7,2)
)
BEGIN
    UPDATE servicos
    SET
        nome_servico = p_nome,
        descricao_servico = p_descricao,
        preco_servico = p_preco
    WHERE id_servico = p_id;
END$$
 
CREATE PROCEDURE remover_servico(
    IN p_id INT
)
BEGIN
    DELETE FROM servicos
    WHERE id_servico = p_id;
END$$

	-- agenda
CREATE PROCEDURE agendar_consulta(
    IN p_data DATETIME,
    IN p_id_cliente INT,
    IN p_id_profissional INT
)
BEGIN
    INSERT INTO agenda (data_consulta, id_cliente, id_profissional, status)
    VALUES (p_data, p_id_cliente, p_id_profissional, 'agendada');
END$$
 
CREATE PROCEDURE editar_consulta(
    IN p_id INT,
    IN p_nova_data DATETIME
)
BEGIN
    UPDATE agenda
    SET data_consulta = p_nova_data
    WHERE id_consulta = p_id AND status = 'agendada';
END$$
 
CREATE PROCEDURE cancelar_consulta(
    IN p_id INT
)
BEGIN
    UPDATE agenda
    SET status = 'cancelada'
    WHERE id_consulta = p_id AND status = 'agendada';
END$$
 
CREATE PROCEDURE realizar_consulta(
    IN p_id INT
)
BEGIN
    UPDATE agenda
    SET status = 'realizada'
    WHERE id_consulta = p_id AND status = 'agendada';
END$$

	-- pagamento
CREATE PROCEDURE registrar_pagamento(
    IN p_id_consulta INT,
    IN p_id_cliente INT,
    IN p_valor DECIMAL(10,2),
    IN p_forma ENUM('dinheiro','cartao_credito','cartao_debito','pix','boleto'),
    IN p_observacao VARCHAR(255)
)
BEGIN
    INSERT INTO pagamentos (
        id_consulta, id_cliente, valor_total,
        data_pagamento, forma_pagamento, status, observacao
    )
    VALUES (
        p_id_consulta, p_id_cliente, p_valor,
        CURDATE(), p_forma, 'pago', p_observacao
    );
END$$
 
CREATE PROCEDURE adicionar_servico_pagamento(
    IN p_id_pagamento INT,
    IN p_id_servico INT,
    IN p_valor DECIMAL(10,2)
)
BEGIN
    INSERT INTO pagamento_servicos (id_pagamento, id_servico, valor_cobrado)
    VALUES (p_id_pagamento, p_id_servico, p_valor);
END$$

	-- usuarios
CREATE PROCEDURE cadastrar_usuario(
    IN p_user VARCHAR(50),
    IN p_password VARCHAR(50),
    IN p_acesso ENUM('admin','recepcionista','profissional','cliente'),
    IN p_id_profissional INT,
    IN p_id_cliente INT
)
BEGIN
    INSERT INTO usuario (
        user_hash, password_hash, acesso,
        id_profissional, id_cliente
    )
    VALUES (
        p_user, p_password, p_acesso,
        p_id_profissional, p_id_cliente
    );
END$$
 
CREATE PROCEDURE remover_usuario(
    IN p_id INT
)
BEGIN
    DELETE FROM usuario
    WHERE id_usuario = p_id;
END$$ 
DELIMITER ;
    
-- inserindo dados na tabela
CALL cadastrar_convenio('Unimed');
CALL cadastrar_convenio('Bradesco');
CALL cadastrar_convenio('Amil');
CALL cadastrar_convenio('SulAmérica');

CALL cadastrar_profissional('Ana Paula', 'Ferreira', NULL, '85586966085', 'SP-45231', 'anapaula@clinicapassini.com', '(11) 91111-1111', 'anapaula@pix');
CALL cadastrar_profissional('Carlos Eduardo', 'Lima', NULL, '17565872059', 'SP-38904', 'carloslima@clinicapassini.com', '(11) 92222-2222', 'carloslima@pix');
CALL cadastrar_profissional('Mariana', 'Souza', NULL, '58472039005', 'SP-52187', 'mariana@clinicapassini.com', '(11) 93333-3333', 'mariana@pix');
    
CALL vincular_convenio_profissional(1, 1); 
CALL vincular_convenio_profissional(1, 2); 
CALL vincular_convenio_profissional(2, 3); 
CALL vincular_convenio_profissional(3, 2); 
    
CALL cadastrar_servico('Consulta de avaliação', 'Avaliação inicial do paciente', 150.00);
CALL cadastrar_servico('Limpeza dental', 'Profilaxia e remoção de tártaro', 200.00);
CALL cadastrar_servico('Restauração', 'Restauração com resina composta', 350.00);
CALL cadastrar_servico('Canal', 'Tratamento endodôntico', 900.00);
CALL cadastrar_servico('Implante', 'Implante de titânio unitário', 3500.00);
    
CALL cadastrar_cliente('Ana Clara', 'Rodrigues', NULL, '(11) 98234-5671', 'anaclara@gmail.com', '98765432101', 1, TRUE);
CALL cadastrar_cliente('Bruno', 'Tavares', NULL, '(11) 97123-4589', 'bruno.tavares@gmail.com', '87654321012', 2, TRUE);
CALL cadastrar_cliente('Helena', 'Carvalho', NULL, '(11) 92789-3456', 'helenacarvalho@hotmail.com', '76543210923', NULL, TRUE);

CALL agendar_consulta('2026-05-26 09:00:00', 1, 1);
CALL agendar_consulta('2026-05-26 10:00:00', 2, 2);
CALL agendar_consulta('2026-05-27 08:30:00', 3, 3);    

CALL realizar_consulta(1);
CALL cancelar_consulta(2);
    
CALL registrar_pagamento(1, 1, 150.00, 'pix', NULL);
CALL adicionar_servico_pagamento(1, 1, 150.00);    

CALL cadastrar_usuario('admin', 'senha_hash_aqui', 'admin', NULL, NULL);
CALL cadastrar_usuario('anapaula', 'senha_hash_aqui', 'profissional', 1, NULL);
CALL cadastrar_usuario('anaclara', 'senha_hash_aqui', 'cliente', NULL, 1);
    
    
    
    
    
    
    
-- LGPD