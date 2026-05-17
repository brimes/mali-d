# Mali-D

Sistema de gestão de marcações e prontuários para clínicas, consultórios, hospitais e médicos.

## Stack

Rails 8.1 · Hotwire · PostgreSQL 16 · Tailwind v4 · Devise + Pundit · ros-apartment (multi-tenant por schema) · FullCalendar · Action Text · Docker Compose (dev) · K8s (prod, futuro).

## Setup local

Pré-requisitos: Docker Desktop ou Rancher Desktop, `make`, `git`.

```bash
cp .env.example .env
make setup        # build + db + seed (primeira vez)
make up           # sobe containers
```

Acessar:

- `http://app.lvh.me:3010` — admin master
  - Login: `admin@mali-d.local` / `changeme123` (configurável em `.env`)
- `http://<subdomain>.lvh.me:3010` — painel da empresa após cadastro

> `lvh.me` resolve para `127.0.0.1`; qualquer subdomínio funciona sem mexer no `/etc/hosts`.

## Comandos do dia-a-dia

```bash
make help          # lista todos
make up            # docker compose up -d
make down          # para containers
make logs          # logs do web
make console       # rails console
make migrate       # roda migrations (public + tenants)
make db-reset      # apaga e recria DB
make routes        # rotas
make test          # RSpec
make psql          # psql no DB de dev
```

## Documentação

| Arquivo                    | Para                                                  |
|----------------------------|-------------------------------------------------------|
| [CLAUDE.md](CLAUDE.md)     | Contexto para agentes de IA (leia antes de mudar nada)|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arquitetura, ADRs, modelo de domínio  |
| [docs/CONVENTIONS.md](docs/CONVENTIONS.md)   | Padrões de código por camada          |
| [Makefile](Makefile)       | Comandos                                              |

## Domínio

- **Empresa** (Clínica, Consultório, Hospital, Médico-PJ) — cada uma vira um schema PG isolado.
- **Perfis**: Admin master, Owner, Médico, Funcionário.
- **Agenda** com consultas (médico + paciente; dia/semana/mês).
- **Prontuário** vinculado à consulta, com histórico cronológico por paciente e versionamento após assinatura.

## Multi-tenant em uma frase

Subdomínio `app` → admin master no schema `public`. Qualquer outro subdomínio cadastrado em `Company.subdomain` → schema PG próprio, isolado, gerenciado pelo `ros-apartment`. Detalhes em [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Roadmap

- [x] Fase 0 — Bootstrap (Rails 8 + Docker)
- [x] Fase 1 — Auth + tenancy + admin master
- [x] Fase 2 — CRUD empresas / médicos / funcionários / pacientes
- [x] Fase 3 — Agenda + calendário (FullCalendar) + consultas
- [x] Fase 4 — Prontuário (Action Text) + histórico + assinatura
- [x] Fase 5 — Admin dashboard cross-tenant
- [ ] Fase 6 — UI refinement, testes, mailer de convite
- [ ] Fase 7 — K8s/Helm para produção
