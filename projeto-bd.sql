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
telefone_cliente_hash VARCHAR(50) NOT NULL,
email_cliente_hash VARCHAR(100) UNIQUE,
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
email_profissional_hash VARCHAR(100) UNIQUE NOT NULL,
telefone_profissional_hash VARCHAR(18) UNIQUE NOT NULL,
pix_hash VARCHAR(50) NOT NULL UNIQUE,
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
    valor_cobrado    DECIMAL(10,2) NOT NULL,

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
    ip_origem       VARCHAR(45) NULL,

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
DELIMITER $$
    -- convênios
CREATE PROCEDURE cadastrar_convenio(
    IN p_nome VARCHAR(50)
)
BEGIN
    INSERT INTO convenios (nome_convenio) VALUES (p_nome);
END$$

CREATE PROCEDURE deletar_convenio(
    IN p_id INT
)
BEGIN
    DELETE FROM convenios WHERE id_convenio = p_id;
END$$

    -- profissionais
CREATE PROCEDURE cadastrar_usuario_profissional(
    IN p_user VARCHAR(50),
    IN p_password VARCHAR(50),
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
    DECLARE v_id_profissional INT;

    -- insere o profissional na tabela de profissionais
    INSERT INTO profissionais (
        nome_profissional,
        sobrenome_profissional,
        nome_social_profissional,
        cpf_profissional_hash,
        cro,
        email_profissional_hash,
        telefone_profissional_hash,
        pix_hash
    )
    VALUES (
        p_nome, p_sobrenome, p_nome_social,
        p_cpf, p_cro, p_email, p_telefone, p_pix
    );

    -- pegando o id do profissional que acabou de ser gerado ao inseri-lo na tabela
    SET v_id_profissional = LAST_INSERT_ID();

    -- cria o usuário já vinculado ao profissional
    INSERT INTO usuario (user_hash, password_hash, acesso, id_profissional)
    VALUES (p_user, p_password, 'profissional', v_id_profissional);
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
        email_profissional_hash = p_email,
        telefone_profissional_hash = p_telefone,
        pix_hash = p_pix
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
CREATE PROCEDURE cadastrar_usuario_cliente(
    IN p_user VARCHAR(50),
    IN p_password VARCHAR(50),
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
    DECLARE v_id_cliente INT;

    -- insere o cliente na tabela clientes
    INSERT INTO clientes (
        nome_cliente, sobrenome_cliente, nome_social_cliente,
        telefone_cliente_hash, email_cliente_hash, cpf_cliente_hash,
        id_convenio, termo_servico
    )
    VALUES (
        p_nome, p_sobrenome, p_nome_social,
        p_telefone, p_email, p_cpf,
        p_id_convenio, p_termo
    );

    -- pega o id do cliente que acabou de ser gerado
    SET v_id_cliente = LAST_INSERT_ID();

    -- cria o usuário já vinculado ao id do cliente 
    INSERT INTO usuario (user_hash, password_hash, acesso, id_cliente)
    VALUES (p_user, p_password, 'cliente', v_id_cliente);
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
        telefone_cliente_hash = p_telefone,
        email_cliente_hash = p_email,
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

-- inserindo os dados

	-- convênios
CALL cadastrar_convenio('Unimed');
CALL cadastrar_convenio('Bradesco');
CALL cadastrar_convenio('Amil');
CALL cadastrar_convenio('SulAmérica');

	-- profissionais 
CALL cadastrar_usuario_profissional('anapaula', 'senha_hash_aqui', 'Ana Paula', 'Ferreira', NULL, '85586966085', 'SP-45231', 'anapaula@clinicapassini.com', '(11) 91111-1111', 'anapaula@pix');
CALL cadastrar_usuario_profissional('carloslima', 'senha_hash_aqui', 'Carlos Eduardo', 'Lima', NULL, '17565872059', 'SP-38904', 'carloslima@clinicapassini.com', '(11) 92222-2222', 'carloslima@pix');
CALL cadastrar_usuario_profissional('marianasouza', 'senha_hash_aqui', 'Mariana', 'Souza', NULL, '58472039005', 'SP-52187', 'mariana@clinicapassini.com', '(11) 93333-3333', 'mariana@pix');

	-- inserindo os admin (basicamente as recepicionistas)
CALL cadastrar_usuario('admin', 'senha_hash_aqui', 'admin', NULL, NULL);

	-- vínculos de convênio dos profissionais
CALL vincular_convenio_profissional(1, 1);
CALL vincular_convenio_profissional(1, 2);
CALL vincular_convenio_profissional(2, 3);
CALL vincular_convenio_profissional(3, 2);

	-- serviços
CALL cadastrar_servico('Consulta de avaliação', 'Avaliação inicial do paciente', 150.00);
CALL cadastrar_servico('Limpeza dental', 'Profilaxia e remoção de tártaro', 200.00);
CALL cadastrar_servico('Restauração', 'Restauração com resina composta', 350.00);
CALL cadastrar_servico('Canal', 'Tratamento endodôntico', 900.00);
CALL cadastrar_servico('Implante', 'Implante de titânio unitário', 3500.00);

	-- clientes + usuários (cliente se registra pelo app)
CALL cadastrar_usuario_cliente('anaclara', 'senha_hash_aqui', 'Ana Clara', 'Rodrigues', NULL, '(11) 98234-5671', 'anaclara@gmail.com', '98765432101', 1, TRUE);
CALL cadastrar_usuario_cliente('brunotavares', 'senha_hash_aqui', 'Bruno', 'Tavares', NULL, '(11) 97123-4589', 'bruno.tavares@gmail.com', '87654321012', 2, TRUE);
CALL cadastrar_usuario_cliente('helenacarvalho', 'senha_hash_aqui', 'Helena', 'Carvalho', NULL, '(11) 92789-3456', 'helenacarvalho@hotmail.com', '76543210923', NULL, TRUE);

	-- agenda
CALL agendar_consulta('2026-05-26 09:00:00', 1, 1);
CALL agendar_consulta('2026-05-26 10:00:00', 2, 2);
CALL agendar_consulta('2026-05-27 08:30:00', 3, 3);

	-- realizar e cancelar consultas
CALL realizar_consulta(1);
CALL cancelar_consulta(2);

	-- pagamentos
CALL registrar_pagamento(1, 1, 150.00, 'pix', NULL);
CALL adicionar_servico_pagamento(1, 1, 150.00);

-- triggers para fazer os registro dos logs automáricamente assim que for feito algo
-- clientes
DELIMITER $$
CREATE TRIGGER trg_clientes_insert
AFTER INSERT ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'clientes',
        'INSERT',
        NEW.id_cliente,
        NULL,
        JSON_OBJECT(
            'nome_cliente', NEW.nome_cliente,
            'sobrenome_cliente', NEW.sobrenome_cliente,
            'telefone_cliente_hash', NEW.telefone_cliente_hash,
            'email_cliente_hash', NEW.email_cliente_hash,
            'cpf_cliente_hash', NEW.cpf_cliente_hash,
            'id_convenio', NEW.id_convenio,
            'termo_servico', NEW.termo_servico
        )
    );
END$$
 
CREATE TRIGGER trg_clientes_update
AFTER UPDATE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'clientes',
        'UPDATE',
        OLD.id_cliente,
        JSON_OBJECT(
            'nome_cliente', OLD.nome_cliente,
            'sobrenome_cliente', OLD.sobrenome_cliente,
            'telefone_cliente_hash', OLD.telefone_cliente_hash,
            'email_cliente_hash', OLD.email_cliente_hash,
            'cpf_cliente_hash', OLD.cpf_cliente_hash,
            'id_convenio', OLD.id_convenio,
            'termo_servico', OLD.termo_servico
        ),
        JSON_OBJECT(
            'nome_cliente', NEW.nome_cliente,
            'sobrenome_cliente', NEW.sobrenome_cliente,
            'telefone_cliente_hash', NEW.telefone_cliente_hash,
            'email_cliente_hash', NEW.email_cliente_hash,
            'cpf_cliente_hash', NEW.cpf_cliente_hash,
            'id_convenio', NEW.id_convenio,
            'termo_servico', NEW.termo_servico
        )
    );
END$$
 
CREATE TRIGGER trg_clientes_delete
AFTER DELETE ON clientes
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'clientes',
        'DELETE',
        OLD.id_cliente,
        JSON_OBJECT(
            'nome_cliente', OLD.nome_cliente,
            'sobrenome_cliente', OLD.sobrenome_cliente,
            'telefone_cliente_hash', OLD.telefone_cliente_hash,
            'email_cliente_hash', OLD.email_cliente_hash,
            'cpf_cliente_hash', OLD.cpf_cliente_hash,
            'id_convenio', OLD.id_convenio,
            'termo_servico', OLD.termo_servico
        ),
        NULL
    );
END$$
 
-- profissionais
CREATE TRIGGER trg_profissionais_insert
AFTER INSERT ON profissionais
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'profissionais',
        'INSERT',
        NEW.id_profissional,
        NULL,
        JSON_OBJECT(
            'nome_profissional', NEW.nome_profissional,
            'sobrenome_profissional', NEW.sobrenome_profissional,
            'cpf_profissional_hash', NEW.cpf_profissional_hash,
            'cro', NEW.cro,
            'email_profissional_hash', NEW.email_profissional_hash,
            'telefone_profissional_hash', NEW.telefone_profissional_hash,
            'status', NEW.status
        )
    );
END$$
 
CREATE TRIGGER trg_profissionais_update
AFTER UPDATE ON profissionais
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'profissionais',
        'UPDATE',
        OLD.id_profissional,
        JSON_OBJECT(
            'nome_profissional', OLD.nome_profissional,
            'sobrenome_profissional', OLD.sobrenome_profissional,
            'cpf_profissional_hash', OLD.cpf_profissional_hash,
            'cro', OLD.cro,
            'email_profissional_hash', OLD.email_profissional_hash,
            'telefone_profissional_hash', OLD.telefone_profissional_hash,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'nome_profissional', NEW.nome_profissional,
            'sobrenome_profissional', NEW.sobrenome_profissional,
            'cpf_profissional_hash', NEW.cpf_profissional_hash,
            'cro', NEW.cro,
            'email_profissional_hash', NEW.email_profissional_hash,
            'telefone_profissional_hash', NEW.telefone_profissional_hash,
            'status', NEW.status
        )
    );
END$$
 
CREATE TRIGGER trg_profissionais_delete
AFTER DELETE ON profissionais
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'profissionais',
        'DELETE',
        OLD.id_profissional,
        JSON_OBJECT(
            'nome_profissional', OLD.nome_profissional,
            'sobrenome_profissional', OLD.sobrenome_profissional,
            'cpf_profissional_hash', OLD.cpf_profissional_hash,
            'cro', OLD.cro,
            'email_profissional_hash', OLD.email_profissional_hash,
            'telefone_profissional_hash', OLD.telefone_profissional_hash,
            'status', OLD.status
        ),
        NULL
    );
END$$
 
-- agenda
CREATE TRIGGER trg_agenda_insert
AFTER INSERT ON agenda
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'agenda',
        'INSERT',
        NEW.id_consulta,
        NULL,
        JSON_OBJECT(
            'data_consulta', NEW.data_consulta,
            'id_cliente', NEW.id_cliente,
            'id_profissional', NEW.id_profissional,
            'status', NEW.status
        )
    );
END$$
 
CREATE TRIGGER trg_agenda_update
AFTER UPDATE ON agenda
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'agenda',
        'UPDATE',
        OLD.id_consulta,
        JSON_OBJECT(
            'data_consulta', OLD.data_consulta,
            'id_cliente', OLD.id_cliente,
            'id_profissional', OLD.id_profissional,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'data_consulta', NEW.data_consulta,
            'id_cliente', NEW.id_cliente,
            'id_profissional', NEW.id_profissional,
            'status', NEW.status
        )
    );
END$$
 
CREATE TRIGGER trg_agenda_delete
AFTER DELETE ON agenda
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'agenda',
        'DELETE',
        OLD.id_consulta,
        JSON_OBJECT(
            'data_consulta', OLD.data_consulta,
            'id_cliente', OLD.id_cliente,
            'id_profissional', OLD.id_profissional,
            'status', OLD.status
        ),
        NULL
    );
END$$
 
-- pagamentos
CREATE TRIGGER trg_pagamentos_insert
AFTER INSERT ON pagamentos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'pagamentos',
        'INSERT',
        NEW.id_pagamento,
        NULL,
        JSON_OBJECT(
            'id_consulta', NEW.id_consulta,
            'id_cliente', NEW.id_cliente,
            'valor_total', NEW.valor_total,
            'forma_pagamento', NEW.forma_pagamento,
            'status', NEW.status
        )
    );
END$$
 
CREATE TRIGGER trg_pagamentos_update
AFTER UPDATE ON pagamentos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'pagamentos',
        'UPDATE',
        OLD.id_pagamento,
        JSON_OBJECT(
            'id_consulta', OLD.id_consulta,
            'id_cliente', OLD.id_cliente,
            'valor_total', OLD.valor_total,
            'forma_pagamento', OLD.forma_pagamento,
            'status', OLD.status
        ),
        JSON_OBJECT(
            'id_consulta', NEW.id_consulta,
            'id_cliente', NEW.id_cliente,
            'valor_total', NEW.valor_total,
            'forma_pagamento', NEW.forma_pagamento,
            'status', NEW.status
        )
    );
END$$
 
CREATE TRIGGER trg_pagamentos_delete
AFTER DELETE ON pagamentos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'pagamentos',
        'DELETE',
        OLD.id_pagamento,
        JSON_OBJECT(
            'id_consulta', OLD.id_consulta,
            'id_cliente', OLD.id_cliente,
            'valor_total', OLD.valor_total,
            'forma_pagamento', OLD.forma_pagamento,
            'status', OLD.status
        ),
        NULL
    );
END$$
 
-- usuário
CREATE TRIGGER trg_usuario_insert
AFTER INSERT ON usuario
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'usuario',
        'INSERT',
        NEW.id_usuario,
        NULL,
        JSON_OBJECT(
            'user_hash', NEW.user_hash,
            'acesso', NEW.acesso,
            'id_profissional', NEW.id_profissional,
            'id_cliente', NEW.id_cliente
        )
    );
END$$
 
CREATE TRIGGER trg_usuario_update
AFTER UPDATE ON usuario
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'usuario',
        'UPDATE',
        OLD.id_usuario,
        JSON_OBJECT(
            'user_hash', OLD.user_hash,
            'acesso', OLD.acesso,
            'id_profissional', OLD.id_profissional,
            'id_cliente', OLD.id_cliente
        ),
        JSON_OBJECT(
            'user_hash', NEW.user_hash,
            'acesso', NEW.acesso,
            'id_profissional', NEW.id_profissional,
            'id_cliente', NEW.id_cliente
        )
    );
END$$
 
CREATE TRIGGER trg_usuario_delete
AFTER DELETE ON usuario
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_log (tabela, operacao, id_registro, dados_antes, dados_depois)
    VALUES (
        'usuario',
        'DELETE',
        OLD.id_usuario,
        JSON_OBJECT(
            'user_hash', OLD.user_hash,
            'acesso', OLD.acesso,
            'id_profissional', OLD.id_profissional,
            'id_cliente', OLD.id_cliente
        ),
        NULL
    );
END$$
 
DELIMITER ;

-- LGPD - Medidas implementadas:
	-- Dados sensíveis criptografados (_hash): cpf, email, telefone, pix
	-- Consentimento explícito do usuário: termo_servico
	-- Rastreabilidade de acessos: auditoria_acesso
	-- Rastreabilidade de alterações: auditoria_log + triggers
	-- Desativação de cadastro em vez de exclusão (preserva histórico)