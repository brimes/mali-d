# Mali-D

Sistema de gestão de marcações e prontuários para clínicas, consultórios, hospitais e médicos.

## Stack

- Ruby 3.3 + Rails 8 (Hotwire/Turbo/Stimulus, importmap, Propshaft)
- PostgreSQL 16
- Tailwind CSS
- Devise + Pundit
- ros-apartment (multi-tenant via schema PG)
- FullCalendar (agenda dia/semana/mês)
- Solid Queue / Solid Cache / Solid Cable
- Docker (dev) / Kubernetes (prod — fase futura)

## Domínio

- **Empresa** (Clínica, Consultório, Hospital, Médico-PJ) — cada uma vira um schema PG isolado.
- **Perfis**: Admin master, Owner, Médico, Funcionário.
- **Agenda** com consultas (médico + paciente, dia/semana/mês).
- **Prontuário** vinculado à consulta, com histórico cronológico por paciente e versionamento após assinatura.

## Setup local (Docker)

```bash
cp .env.example .env
docker compose build
docker compose up -d db
docker compose run --rm web bin/rails db:prepare db:seed
docker compose up
```

Acessar:

- `http://app.lvh.me:3010` — área admin master / login global
- `http://<subdominio>.lvh.me:3010` — área da empresa após cadastro

`lvh.me` resolve para `127.0.0.1` automaticamente, então qualquer subdomínio funciona sem mexer no `/etc/hosts`.

## Admin master inicial

Após `db:seed`, login com:

- Email: valor de `ADMIN_EMAIL` (default `admin@mali-d.local`)
- Senha: valor de `ADMIN_PASSWORD` (default `changeme123` — alterar em produção)

## Comandos úteis

```bash
docker compose run --rm web bin/rails c            # console
docker compose run --rm web bundle exec rspec      # testes
docker compose run --rm web bin/rails db:migrate   # migrations
docker compose exec db psql -U postgres mali_d_development  # psql
```

## Estrutura multi-tenant

- Schema `public`: `users`, `companies`, `memberships` (globais).
- Schema por empresa: `doctors`, `employees`, `patients`, `appointments`, `medical_records`.
- Roteamento: subdomínio (`<subdominio>.lvh.me`) → `Apartment::Tenant.switch!(subdomain)`.

## Roadmap

- [x] Fase 0 — Bootstrap (Rails 8 + Docker + Gemfile)
- [ ] Fase 1 — Auth (Devise) + tenancy (apartment) + seed admin
- [ ] Fase 2 — CRUD empresas / médicos / funcionários / pacientes
- [ ] Fase 3 — Agenda + calendário (FullCalendar) + consultas
- [ ] Fase 4 — Prontuário + histórico do paciente
- [ ] Fase 5 — Área admin master (dashboards)
- [ ] Fase 6 — Manifestos K8s / Helm para produção
