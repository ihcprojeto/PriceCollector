# PriceCollector

## 1. Visão Geral do Projeto

### Nome do Projeto

PriceCollector

### Objetivo Principal

Automatizar e gerenciar o processo de coleta de preços em estabelecimentos comerciais, permitindo o acompanhamento operacional das demandas, controle das coletas realizadas e monitoramento da produtividade dos colaboradores.

### Problema que Resolve

Processos manuais de coleta de preços costumam gerar inconsistências, retrabalho e dificuldade de acompanhamento da execução das atividades. O sistema centraliza todas as informações em uma única plataforma, permitindo rastreabilidade, controle e análise dos resultados.

### Contexto de Uso

O sistema é utilizado em operações de pesquisa e monitoramento de preços, onde colaboradores realizam coletas em lojas previamente cadastradas, seguindo demandas específicas definidas pela organização.

---

## 2. Público-Alvo

### Administradores

Responsáveis pela gestão completa do sistema, incluindo usuários, lojas, produtos, demandas e acompanhamento de indicadores.

### Supervisores

Responsáveis pelo acompanhamento da execução das demandas, monitoramento da produtividade da equipe e análise dos resultados das coletas.

### Coletores

Responsáveis pela execução das coletas de preços utilizando dispositivos móveis e scanner de código de barras.

---

## 3. Funcionalidades

### Gestão de Usuários

* Cadastro de usuários
* Edição de perfil
* Alteração de senha
* Controle de dispositivos utilizados
* Controle de permissões

### Gestão de Lojas

* Cadastro de lojas
* Edição de lojas
* Exclusão de lojas
* Controle de demandas por loja

### Gestão de Produtos

* Cadastro de produtos
* Edição de produtos
* Pesquisa de produtos
* Importação em lote via planilhas Excel (.xlsx)

### Gestão de Demandas

* Criação de demandas
* Edição de demandas
* Cancelamento de demandas
* Reativação de demandas canceladas
* Controle de progresso das demandas

### Coleta de Preços

* Scanner de código de barras
* Validação de produtos
* Registro de preços coletados
* Histórico de coletas
* Edição de coletas
* Exclusão de coletas

### Dashboard Gerencial

* Indicadores operacionais
* Pendências
* Progresso geral
* Quantidade de produtos coletados
* Produtividade global

### Produtividade

* Ranking da equipe
* Produção por hora
* Participação por loja
* Indicadores individuais
* Indicadores globais

### Histórico e Auditoria

* Histórico de coletas
* Histórico de dispositivos utilizados
* Rastreabilidade das operações

---

## 4. Tecnologias Utilizadas

### Frontend

* Flutter
* Dart

### Backend e Serviços

* Firebase Authentication
* Cloud Firestore
* Firebase Storage

### Bibliotecas e Recursos

* Scanner de código de barras
* Manipulação de arquivos Excel (.xlsx)
* Geração de gráficos e indicadores
* Gerenciamento de estado (conforme arquitetura implementada)

---

## 5. Arquitetura

### Frontend

Aplicativo Flutter responsável pela interface do usuário, navegação e apresentação dos dados.

### Camada de Negócio

Responsável pelas regras de negócio, validações e processamento das operações do sistema.

### Camada de Dados

Responsável pela comunicação com os serviços Firebase.

### Banco de Dados

Cloud Firestore estruturado em coleções e subcoleções conforme definido em `firestore.md`.

### Estrutura Simplificada

Usuário
↓
Flutter App
↓
Services / Repositories
↓
Firebase Authentication
↓
Cloud Firestore
↓
Storage

---

## 6. Fluxo de Uso

### Fluxo Principal de Coleta

1. Usuário realiza login.
2. Seleciona o dispositivo utilizado.
3. Acessa suas demandas disponíveis.
4. Seleciona uma loja.
5. Visualiza produtos pendentes.
6. Escaneia ou informa o código de barras.
7. Sistema valida o produto.
8. Usuário registra o preço coletado.
9. A coleta é armazenada no Firestore.
10. Os indicadores são atualizados automaticamente.
11. A produtividade do colaborador é recalculada.

### Fluxo Administrativo

1. Administrador realiza login.
2. Gerencia usuários.
3. Gerencia lojas.
4. Gerencia produtos.
5. Cria demandas.
6. Acompanha indicadores.
7. Monitora produtividade da equipe.

---

## 7. Regras de Negócio

### Usuários

* Todo usuário possui um histórico de dispositivos utilizados.
* Alterações de perfil exigem validação da senha atual.
* Alterações de e-mail devem atualizar Firebase Authentication e Firestore.

### Produtos

* Não podem existir produtos duplicados com o mesmo barcode na mesma demanda.
* O barcode é considerado identificador único para validações operacionais.

### Demandas

* Toda loja possui sua própria subcoleção de demandas.
* Demandas podem ser canceladas e posteriormente reativadas.
* Demandas canceladas não devem impactar indicadores operacionais.

### Coletas

* Cada coleta representa um produto coletado.
* Produtos coletados podem ser editados.
* Ao excluir uma coleta, o produto retorna ao estado pendente.
* Coletas devem manter vínculo com:

  * loja
  * demanda
  * usuário
  * produto

### Lojas

* Ao excluir uma loja, todas as coletas relacionadas devem ser removidas.
* Lojas excluídas não devem impactar:

  * pendências
  * produtividade
  * rankings
  * dashboards
  * progressões
  * indicadores

### Produtividade

* Indicadores devem considerar apenas dados válidos e ativos.
* Lojas removidas não devem participar dos cálculos.
* Demandas inválidas ou canceladas não devem impactar os resultados.

### Scanner

* Códigos de barras inválidos devem ser rejeitados.
* Apenas produtos válidos podem seguir para o fluxo de coleta.

---

## 8. Estrutura de Dados

A estrutura completa das coleções, documentos, relacionamentos e subcoleções encontra-se documentada no arquivo:

[assets/context/firestore.md](assets/context/firestore.md)
