# Projeto BD - Clínica Passini 🦷

Projeto de banco de dados relacional para gerenciamento de uma clínica (odontológica), desenvolvido em MySQL. Modela clientes, profissionais, convênios, serviços, agendamentos e pagamentos, com controle de acesso por usuários e auditoria completa de alterações.

## Funcionalidades

- **Cadastro de clientes** e **profissionais**, com vínculo a convênios e especialidades/serviços atendidos.
- **Controle de usuários** com níveis de acesso (`admin`, `recepcionista`, `profissional`, `cliente`).
- **Agendamento de consultas**, com status (`agendada`, `realizada`, `cancelada`).
- **Registro de pagamentos**, com forma de pagamento (`dinheiro`, `cartão`, `pix`, `boleto`) e detalhamento por serviço cobrado.
- **Auditoria automática** (via triggers) de todas as operações de `INSERT`, `UPDATE` e `DELETE` nas tabelas principais, além de log de login/logout dos usuários.
- **Procedures** para as principais operações de negócio (cadastrar, editar, remover, agendar, cancelar, registrar pagamento, etc.), evitando manipulação direta das tabelas.

## Estrutura do banco de dados

| Tabela | Descrição |
|---|---|
| `convenios` | Convênios atendidos pela clínica |
| `clientes` | Dados dos clientes/pacientes |
| `profissionais` | Dados dos profissionais (com CRO) |
| `usuario` | Usuários do sistema e seus níveis de acesso |
| `profissionais_convenio` | Vínculo entre profissionais e convênios atendidos |
| `servicos` | Serviços oferecidos pela clínica |
| `especialidadeXprofissional` | Vínculo entre profissionais e serviços que realizam |
| `agenda` | Agendamento das consultas |
| `pagamentos` | Pagamentos referentes às consultas |
| `pagamento_servicos` | Detalhamento dos serviços cobrados em cada pagamento |
| `auditoria_log` | Log de alterações (insert/update/delete) nas tabelas principais |
| `auditoria_acesso` | Log de login, logout e tentativas de login falhas |

### Procedures disponíveis

Cadastro, edição e remoção de convênios, profissionais, clientes, serviços e usuários; vínculo entre profissionais/convênios/serviços; agendamento, edição, cancelamento e realização de consultas; registro de pagamentos e adição de serviços a um pagamento.

### Triggers de auditoria

Todas as tabelas críticas (`clientes`, `profissionais`, `agenda`, `pagamentos`, `usuario`) possuem triggers de `INSERT`, `UPDATE` e `DELETE` que registram automaticamente o estado anterior e posterior de cada operação na tabela `auditoria_log`.

## Como executar

Pré-requisito: MySQL (ou compatível, como MariaDB) instalado.

```bash
git clone https://github.com/MuriloPassini/PROJETO-BD-JOYCEZINHA.git
cd PROJETO-BD-JOYCEZINHA

# Criar o banco, tabelas, procedures e triggers
mysql -u seu_usuario -p < projeto-bd.sql

# (Opcional) Rodar consultas de apoio para conferir os dados
mysql -u seu_usuario -p < script_apoio.sql
```

O script cria automaticamente o banco `clinica_passini` caso ele ainda não exista.

## Documentação

Mais detalhes sobre o projeto, modelagem e decisões de design estão disponíveis no arquivo [`Relatório_Projeto_BD.docx`](Relatório_Projeto_BD.docx).

## Licença

Este projeto está sob a licença Apache 2.0. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
