CREATE DATABASE IF NOT EXISTS clinica_passini;
USE clinica_passini;

-- tabela de todos os convênios que os médicos da clínas atendem
CREATE TABLE convenios(
id_convenio INT AUTO_INCREMENT PRIMARY KEY,
nome_convenio VARCHAR(50) NOT NULL
);

-- tabela dos profissionais
CREATE TABLE profissionais(
id_profissional INT AUTO_INCREMENT PRIMARY KEY,
nome_profissional VARCHAR(100) NOT NULL,
cpf_profissional VARCHAR(11) UNIQUE NOT NULL,
cro VARCHAR(20) UNIQUE NOT NULL,
email_profissional VARCHAR(100) UNIQUE NOT NULL,
telefone_profissional VARCHAR(18) UNIQUE NOT NULL,
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

-- tabela dos clientes
CREATE TABLE clientes(
id_cliente INT AUTO_INCREMENT PRIMARY KEY,
nome_cliente VARCHAR(100) NOT NULL,
telefone_cliente VARCHAR(50) NOT NULL,
cpf_cliente VARCHAR(11) UNIQUE NOT NULL,
id_convenio INT,
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
