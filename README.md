# nyc-taxi-platform-infra

Infraestrutura local da plataforma **NYC Taxi Data Lake** — orquestra todos os microserviços via Docker Compose com LocalStack (S3), Kafka, Kafka UI e Airflow.

## 📦 Repositórios da plataforma

| Repo | Função |
|------|--------|
| **nyc-taxi-platform-infra** (este) | Orquestração, docker-compose, LocalStack, Kafka, Airflow |
| [nyc-taxi-trip-producer](#) | Lê CSV → publica eventos no Kafka (Java 21) |
| [nyc-taxi-trip-consumer](#) | Consome Kafka → escreve Iceberg no S3 (Java 21) |
| [nyc-taxi-analytics-pipelines](#) | DAGs Airflow + queries DuckDB |

## 🚀 Setup local (modo dev — clone lado-a-lado)

### 1. Clonar todos os repos no mesmo diretório pai

```bash
mkdir ~/nyc-taxi && cd ~/nyc-taxi
git clone https://github.com/SEU-USER/nyc-taxi-platform-infra.git
git clone https://github.com/SEU-USER/nyc-taxi-trip-producer.git
git clone https://github.com/SEU-USER/nyc-taxi-trip-consumer.git
git clone https://github.com/SEU-USER/nyc-taxi-analytics-pipelines.git
```

Estrutura final:
```
~/nyc-taxi/
├── nyc-taxi-platform-infra/      ← você está aqui
├── nyc-taxi-trip-producer/
├── nyc-taxi-trip-consumer/
└── nyc-taxi-analytics-pipelines/
```

### 2. Baixar o dataset

Baixe `train.csv` do [Kaggle NYC Taxi Fare](https://www.kaggle.com/c/new-york-city-taxi-fare-prediction) e coloque em:
```
nyc-taxi-platform-infra/data/train.csv
```

### 3. Subir tudo

```bash
cd nyc-taxi-platform-infra
cp .env.example .env
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

O `docker-compose.dev.yml` faz **build do código local** dos repos vizinhos (`../nyc-taxi-trip-producer`, etc).

### 4. Acessar

- **Kafka UI:** http://localhost:8081
- **Airflow:** http://localhost:8080 (admin / admin)
- **LocalStack S3:** http://localhost:4566

## 🧪 Modos de execução

| Comando | O que faz |
|---------|-----------|
| `docker compose up` | Sobe só infra (Kafka, LocalStack, Airflow) |
| `docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build` | Sobe infra + builda services do código local |
| `docker compose -f docker-compose.yml -f docker-compose.prod.yml up` | Sobe infra + puxa imagens do GHCR |

## 🗺️ Caminho para AWS (produção)

| Local | AWS |
|-------|-----|
| Kafka (Bitnami) | **MSK** |
| LocalStack S3 | **S3** |
| Airflow local | **MWAA** |
| HadoopCatalog | **Glue Catalog** |
| DuckDB | **Athena** |

Veja `terraform/` para o IaC equivalente.

## 📜 Licença
MIT
