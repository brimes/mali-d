# Arquitetura — Mali-D

## Visão de alto nível

```
                ┌─────────────────────────────────────────────────┐
                │              Browser (Hotwire)                  │
                └─────────────────────────────────────────────────┘
                                    │ HTTP/WS
                                    ▼
   ┌────────────────────────────────────────────────────────────────┐
   │                      Rails 8 monolito                          │
   │                                                                │
   │  ┌────────────────┐    ┌─────────────────────┐                 │
   │  │ app.lvh.me     │    │ <sub>.lvh.me        │                 │
   │  │ Admin master   │    │ Painel da empresa   │                 │
   │  │ (schema public)│    │ (schema <sub>)      │                 │
   │  └────────────────┘    └─────────────────────┘                 │
   │           │                       │                            │
   │           ▼                       ▼                            │
   │   Apartment::Elevators::Subdomain (middleware)                 │
   │   ↓ troca search_path do Postgres por request                  │
   └────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
   ┌────────────────────────────────────────────────────────────────┐
   │              PostgreSQL 16 (mali_d_development)                │
   │                                                                │
   │  schema public:                                                │
   │    users, companies, memberships,                              │
   │    action_text_rich_texts, active_storage_*                    │
   │                                                                │
   │  schema clinica-alfa:                                          │
   │    doctors, employees, patients, appointments,                 │
   │    medical_records, medical_record_versions                    │
   │                                                                │
   │  schema clinica-beta:                                          │
   │    (idem, dados isolados)                                      │
   └────────────────────────────────────────────────────────────────┘
```

## Modelo de domínio

```
            ┌──────────┐
            │   User   │  (public)
            │  Devise  │
            └────┬─────┘
                 │ 1..N
                 ▼
          ┌─────────────┐         ┌─────────┐
          │  Membership │────────▶│ Company │  (public)
          │ role: enum  │         │ subdom. │
          └─────────────┘         └────┬────┘
                                       │ provisiona schema PG
                                       ▼
   ════════════════════════════════════════════════════════════════
                    Schema do tenant (clinica-alfa)
   ════════════════════════════════════════════════════════════════

   ┌────────┐         ┌───────────────┐         ┌─────────┐
   │ Doctor │────────▶│  Appointment  │◀────────│ Patient │
   │ (CRM)  │  1..N   │ starts/ends   │   1..N  │ (CPF)   │
   └────────┘         │ status: enum  │         └─────────┘
                      └──────┬────────┘
                             │ 1..1
                             ▼
                      ┌───────────────┐
                      │ MedicalRecord │
                      │ body (Trix)   │
                      │ signed_at     │
                      └──────┬────────┘
                             │ 1..N (após assinar)
                             ▼
                      ┌──────────────────────┐
                      │ MedicalRecordVersion │
                      │ (snapshot imutável)  │
                      └──────────────────────┘

   ┌──────────┐
   │ Employee │   (sem relações; staff administrativo)
   └──────────┘
```

## Decisões arquiteturais (ADRs resumidas)

### ADR-001: Schema-per-tenant (apartment) ao invés de coluna `company_id`

- **Contexto:** dados médicos sensíveis, requisito de isolamento forte.
- **Decisão:** `ros-apartment` com `Subdomain` elevator.
- **Trade-off:** complexidade extra em migrations (rodam em todos os schemas), backups por tenant mais ricos, isolamento natural impede vazamento cross-tenant.
- **Não pegar atalho:** nada de `where(company_id:)` para isolar — confia no `search_path`.

### ADR-002: `User`/`Company`/`Membership` no schema `public`

- Auth precisa ser global (um usuário pode pertencer a N empresas).
- Listados em `Apartment.excluded_models` para não trocar de schema quando consultados.
- IDs cross-schema (ex: `Doctor.user_id`) são **inteiros sem FK** — `User.find_by(id: ...)` resolve no public.

### ADR-003: Admin master no subdomínio reservado `app`

- Subdomínios em `RESERVED_TENANT_SUBDOMAINS` (`app`, `www`, `admin`, `api`, `root`, `public`) ficam no schema `public`.
- Empresas não podem usar esses nomes (validação no model).
- Admin master é qualquer `User` com `role: :admin`.

### ADR-004: Senhas/convites — sem email transacional no MVP

- `InviteUserService` gera senha aleatória e loga em `Rails.logger.info`.
- Próxima fase: substituir por `Devise::Mailer` + Active Job (Solid Queue já está configurado).

### ADR-005: Prontuário com Action Text + assinatura imutável

- Body é `has_rich_text` (Trix).
- `MedicalRecord#sign!` seta `signed_at` e `signed_by_id`.
- Após assinado, controller bloqueia `update`. Para evitar perda de auditoria, `snapshot_version!` salva o body como string em `MedicalRecordVersion` antes de assinar.
- Pendente: bloquear update no nível do model com callback (defesa em profundidade).

### ADR-006: FullCalendar via `<script>` global, fora do importmap

- `@fullcalendar/daygrid` importa subpaths (`@fullcalendar/core/index.js`, `internal.js`, `preact.js`) que não estão no importmap.
- Bundling com esbuild seria caro para Hotwire-only stack.
- Carregamos `index.global.min.js` dinamicamente no `connect()` do Stimulus controller. Cache do browser amortiza.

## Roteamento

```
GET  /                                  → home#index (redireciona conforme contexto)
GET  /users/sign_in                     → Devise sessions#new

# Admin (subdomínio reservado, ex: app.lvh.me)
GET  /admin                             → Admin::Dashboard#index
*    /admin/companies                   → Admin::Companies CRUD

# Tenant (subdomínio = company.subdomain)
GET  /dashboard                         → Dashboard#show
*    /doctors                           → Doctors CRUD
*    /employees                         → Employees CRUD
*    /patients                          → Patients CRUD
GET  /patients/:id/history              → Patients#history
*    /appointments                      → Appointments CRUD
GET  /appointments.json                 → JSON p/ FullCalendar
*    /appointments/:aid/medical_record  → MedicalRecords actions
POST /appointments/:aid/medical_record/sign → MedicalRecords#sign
```

## Pontos de extensão previstos

- Mailer real para convites (Solid Queue já existe)
- Pundit policies fine-grained por modelo
- Roles dentro do tenant: visão restrita do médico (só seus pacientes)
- Endpoint público de status (`/up` já existe)
- Manifestos K8s + Helm (Fase 6)
- Observabilidade: logs estruturados, OpenTelemetry
