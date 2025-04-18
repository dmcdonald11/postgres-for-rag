# PostgreSQL + pgvector + Apache AGE Docker Stack

This stack combines:
- **PostgreSQL 16.6**
- **pgvector** for vector search
- **Apache AGE** for graph database support

## Usage

This Docker Container creates a PostgresSQL server that will support LightRAG AI as its postgres database for Vector, Graph and Document storage.
1. Clone this repo:
   ```bash
   git clone https://github.com/yourusername/postgres-for-rag.git
   cd postgres-for-rag
   docker-compose up -d --build
