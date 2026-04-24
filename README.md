# 🛰️ NYC Taxi Data Lake – Platform Infra

Este repositório é o **núcleo de infraestrutura local** da plataforma **NYC Taxi Data Lake**, um projeto end-to-end de engenharia de dados que simula um pipeline real de ingestão, processamento e visualização de corridas de táxi de Nova York.

A infra orquestra **todos os serviços de apoio** via **Docker Compose**, fornecendo um ambiente equivalente ao de nuvem (AWS) totalmente local, baseado em **LocalStack (S3)**, **Apache Kafka (KRaft)**, **Kafka UI** e **Apache Airflow**.

A plataforma é capaz de:

- Subir um cluster Kafka local em modo **KRaft** (sem Zookeeper)
- Emular o **Amazon S3** com LocalStack como camada de Data Lake
- Orquestrar pipelines ETL/ELT com **Apache Airflow**
- Buildar e executar os microserviços **Producer** e **Consumer** a partir do código local (modo dev) ou de imagens publicadas no GHCR (modo prod)
- Servir como base reproduzível para o caminho de migração até a **AWS** (MSK, S3, MWAA, Glue, Athena)

---

## 🗺️ Arquitetura da Plataforma

O diagrama abaixo descreve o fluxo end-to-end dos dados, desde a ingestão das corridas no Kafka até a visualização no dashboard React:

![Arquitetura NYC Taxi Data Lake](./dash/src/assets//ArchPlatform.jpg)

**Fluxo resumido:**

1. **`nyc-taxi-trip-producer`** lê o dataset NYC TLC e publica trips em JSON no **Kafka KRaft**.
2. **`nyc-taxi-trip-consumer`** (Spring Boot) consome do Kafka, aplica filtros mínimos e grava em **Parquet** na zona `s3://.../raw/taxi-trips/` (LocalStack S3).
3. **Airflow** orquestra duas DAGs no repositório **`nyc-taxi-analytics-pipelines`**:
   - **`raw → silver`**: lê os Parquets via **DuckDB**, valida e grava em **Apache Iceberg** particionado por `year/month` em `s3://.../silver/trips/`.
   - **`export_arcs_geojson`**: gera uma amostra estratificada via DuckDB e exporta para `s3://.../exports/arcs.geojson`.
4. O **Dashboard React** (Mapbox + **deck.gl ArcLayer**) consome o GeoJSON via CDN e renderiza os arcos pickup → dropoff.

| Zona | Formato | Quem escreve | Propósito |
|---|---|---|---|
| `raw/` | Parquet | Consumer | Dados crus, fiéis à origem |
| `silver/` | Iceberg | DAG `raw → silver` | Dados validados, particionados, queryáveis |
| `exports/` | GeoJSON | DAG `export_arcs_geojson` | Artefato pronto para o frontend |

---

## 🎯 Objetivo do Projeto

Construir uma **plataforma de Data Lake moderna**, totalmente reproduzível em ambiente local, que demonstre na prática os pilares de uma arquitetura de dados em nuvem:

- **Ingestão em streaming** (Kafka)
- **Armazenamento em camadas** (raw Parquet → silver Iceberg → exports GeoJSON)
- **Orquestração de jobs** (Airflow)
- **Visualização interativa** (dashboard React + Mapbox + deck.gl)

A solução serve como referência para times que desejam validar pipelines de dados antes de promovê-los para a AWS, evitando custos durante o desenvolvimento.

---

## 📦 Repositórios da Plataforma

| Repositório | Função |
|---|---|
| **nyc-taxi-platform-infra** *(este)* | Orquestração, docker-compose, LocalStack, Kafka, Airflow |
| [nyc-taxi-trip-producer](#) | Lê CSV de corridas → publica eventos no Kafka (Java 21 / Spring Boot) |
| [nyc-taxi-trip-consumer](#) | Consome Kafka → escreve **Parquet** no S3 (Java 21 / Spring Boot) |
| [nyc-taxi-analytics-pipelines](#) | DAGs Airflow + queries DuckDB + dashboard React |

---

## 📁 Estrutura do Projeto

```
nyc-taxi-platform-infra/
│
├── docker/
│   ├── airflow/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   └── localstack/
│       └── init-s3.sh
│
├── data/
│   └── train.csv                 ← dataset Kaggle (não versionado)
│
├── terraform/                    ← IaC equivalente para AWS (MSK, S3, MWAA, Glue)
│
├── docker-compose.yml            ← infra base (Kafka, LocalStack, Airflow, Kafka UI)
├── docker-compose.dev.yml        ← build dos services a partir do código local
├── docker-compose.prod.yml       ← pull das imagens publicadas no GHCR
│
├── .env.example
└── README.md
```

---

## ⚙️ Como Executar

### 1) Clonar todos os repositórios lado-a-lado

O `docker-compose.dev.yml` espera encontrar os repositórios irmãos no **mesmo diretório pai**:

```bash
mkdir ~/nyc-taxi && cd ~/nyc-taxi

git clone https://github.com/Phellype-Guilherme/nyc-taxi-datalake-platform.git
git clone https://github.com/Phellype-Guilherme/nyc-taxi-trip-producer.git
git clone https://github.com/Phellype-Guilherme/nyc-taxi-trip-consumer.git
git clone https://github.com/Phellype-Guilherme/nyc-taxi-analytics-pipelines.git
```

Estrutura final esperada:

```
~/nyc-taxi/
├── nyc-taxi-platform-infra/      ← você está aqui
├── nyc-taxi-trip-producer/
├── nyc-taxi-trip-consumer/
└── nyc-taxi-analytics-pipelines/
```

---

### 2) Baixar o dataset

Faça o download do `train.csv` da competição [NYC Taxi Fare Prediction (Kaggle)](https://www.kaggle.com/c/new-york-city-taxi-fare-prediction) e coloque em:

```
nyc-taxi-platform-infra/data/train.csv
```

---

### 3) Configurar variáveis de ambiente

```bash
cp .env.example .env
```

Edite o `.env` se necessário (credenciais LocalStack, portas, etc).

---

### 4) Subir a stack completa (modo dev)

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

Esse comando:

- Sobe **Kafka KRaft**, **Kafka UI**, **LocalStack S3** e **Airflow**
- Faz **build** do Producer e do Consumer a partir do código-fonte local
- Cria automaticamente o bucket `nyc-taxi-datalake` no LocalStack

---

### 5) Acessar as interfaces

| Serviço | URL | Credenciais |
|---|---|---|
| **Kafka UI** | http://localhost:8081 | — |
| **Airflow** | http://localhost:8080 | `admin` / `admin` |
| **LocalStack S3** | http://localhost:4566 | `test` / `test` |

---

## 🧪 Modos de Execução

| Comando | O que faz |
|---|---|
| `docker compose up` | Sobe **somente** a infra (Kafka, LocalStack, Airflow) |
| `docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build` | Sobe infra **+ buildа** services a partir do código local |
| `docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build`<br/>`docker compose -f docker-compose.yml -f docker-compose.prod.yml up` | Sobe infra **+ puxa** imagens do GHCR (modo produção local) |

---

## 🗺️ Arquitetura

Fluxo de dados end-to-end:

```
Producer ──► Kafka (KRaft) ──► Consumer ──► S3 raw/ (Parquet)
                                                 │
                                                 ▼
                                        Airflow DAG: silver
                                                 │
                                                 ▼
                                        S3 silver/ (Iceberg)
                                                 │
                                                 ▼
                                Airflow DAG: export_arcs_geojson
                                                 │
                                                 ▼
                                S3 exports/arcs.geojson ──► Dashboard React
```

> O diagrama completo está disponível em `docs/architecture.png` e `docs/architecture.drawio`.

---

## 🗂️ Zonas do Data Lake

| Zona | Formato | Quem escreve | Propósito |
|---|---|---|---|
| `raw/` | Parquet | Consumer (Spring Boot) | Dados crus, fiéis à origem |
| `silver/` | Iceberg | DAG `raw_to_silver` | Dados validados e particionados (`year/month`) |
| `exports/` | GeoJSON | DAG `export_arcs_geojson` | Artefato pronto para o dashboard |

---

## ☁️ Caminho para AWS (Produção)

A infra local foi desenhada como **espelho 1:1** dos serviços gerenciados da AWS, facilitando a migração para produção:

| Local | AWS |
|---|---|
| Kafka (Apache KRaft) | **Amazon MSK** |
| LocalStack S3 | **Amazon S3** |
| Airflow local | **Amazon MWAA** |
| HadoopCatalog (Iceberg) | **AWS Glue Catalog** |
| DuckDB | **Amazon Athena** |

> O diretório `terraform/` contém o IaC equivalente para provisionar todos esses recursos na AWS.

---

## 🧠 Tecnologias Utilizadas

### Mensageria & Streaming
- **Apache Kafka 3.7.1** (modo KRaft, sem Zookeeper)
- **Kafka UI** (Provectus) para inspeção de tópicos

### Storage
- **LocalStack** (emulação local de S3)
- **Apache Iceberg** (formato de tabela transacional)
- **Apache Parquet** (formato colunar para a camada raw)

### Orquestração
- **Apache Airflow** (scheduler + webserver)
- **DuckDB** dentro das DAGs para consultas ad-hoc em Parquet

### Microserviços
- **Java 21 + Spring Boot** (Producer e Consumer)

### Infraestrutura
- **Docker Compose** (orquestração local)
- **Terraform** (IaC para AWS)

---

## 📚 Bibliotecas e Imagens Principais

- **apache/kafka:3.7.1** – broker Kafka em modo KRaft
- **provectuslabs/kafka-ui** – interface web para Kafka
- **localstack/localstack** – emulação de serviços AWS
- **apache/airflow:2.x** – orquestrador de pipelines
- **eclipse-temurin:21-jre** – runtime Java dos services

---

## 📜 Licença

Distribuído sob a licença **MIT**. Veja o arquivo `LICENSE` para mais detalhes.

---

## 👨‍💻 Autor

**Phellype Guilherme Maturano Pereira**
