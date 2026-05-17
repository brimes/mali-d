# CLAUDE.md — Mali-D

Contexto persistente para agentes de IA (Claude Code, etc.) trabalhando neste projeto.
Leia este arquivo antes de propor mudanças.

## O que é

Mali-D é um sistema de gestão de marcações e prontuários médicos. Cada **cliente** (Clínica, Consultório, Hospital, Médico-PJ) é um **tenant** com schema PostgreSQL próprio. O agente atua sobre um monolito Rails 8 com Hotwire.

## Stack

- Ruby 3.3, Rails 8.1, Hotwire (Turbo + Stimulus), Propshaft, importmap
- PostgreSQL 16
- Tailwind CSS v4 (via `tailwindcss-rails`)
- Devise (auth) + Pundit (authz)
- `ros-apartment` (multi-tenant via schema PG)
- FullCalendar 6 (carregado via `<script>` global do CDN, não importmap — ver convenções)
- Action Text + Trix (prontuário)
- RSpec + FactoryBot + Faker
- Docker Compose para dev

## Comandos

**Sempre via `make`** — nunca chame `docker compose` direto, evita drift entre devs.

```bash
make setup        # primeira vez (build + db + seed)
make up           # sobe containers
make down         # para
make logs         # logs do web
make console      # rails c
make migrate      # roda migrations (public + tenants)
make db-reset     # apaga e recria tudo
make routes       # lista rotas
make test         # RSpec
```

`make help` lista tudo.

## Convenções obrigatórias

### Multi-tenant — leia com atenção

**Modelos globais (vivem no schema `public`):**
- `User`, `Company`, `Membership`
- Listados em `config/initializers/apartment.rb` como `excluded_models`
- **NÃO** criar foreign keys de tabelas tenant para essas globais — apartment troca `search_path` e a FK ficaria órfã. Use `user_id` como inteiro simples e busque com `User.find_by(id: ...)`.

**Modelos tenant (vivem em cada schema de empresa):**
- `Doctor`, `Employee`, `Patient`, `Appointment`, `MedicalRecord`, `MedicalRecordVersion`
- Migrations em `db/migrate/` rodam em TODOS os schemas (public + cada tenant). A duplicação em `public` é inerte.
- Foreign keys entre modelos tenant são OK e devem ser usadas.

**Subdomínios reservados** (não podem ser tenant): `app`, `www`, `admin`, `api`, `root`, `public`. Lista em `Company::RESERVED_SUBDOMAINS` e `RESERVED_TENANT_SUBDOMAINS` (initializer).

**Subdomínio `app`** = entrypoint do admin master (admin@mali-d.local). Áreas:
- `app.lvh.me:3010` → admin master (controllers em `Admin::`)
- `<subdomain>.lvh.me:3010` → painel da empresa (controllers raiz)

**Trocar de tenant em código:**
```ruby
Apartment::Tenant.switch("clinica-foo") do
  Appointment.count
end
# ATENÇÃO: use `switch` (com bloco). `process` foi removido na ros-apartment 3.x.
```

Para iterar todos: `Company.find_each { |c| Apartment::Tenant.switch(c.subdomain) { ... } }`. Ver `AdminMetricsService` como referência.

### Controllers

Hierarquia:
```
ApplicationController        # autentica, expõe current_company / admin_host?
├── Admin::BaseController    # exige admin_host? + admin?, layout "admin"
│   ├── Admin::DashboardController
│   └── Admin::CompaniesController
└── TenantBaseController     # exige current_company + membership (admin bypass)
    ├── DashboardController
    ├── DoctorsController
    ├── EmployeesController
    ├── PatientsController
    ├── AppointmentsController
    └── MedicalRecordsController
```

Toda controller nova de área da empresa **deve** herdar de `TenantBaseController`. Não chame `Doctor.find` em `ApplicationController` direto — o tenant pode não estar ativo.

### Services

`app/services/` para lógica que toca múltiplos modelos OU múltiplos tenants. Exemplos:
- `InviteUserService` — cria User+Membership no public, linka tenant record
- `AdminMetricsService` — agrega métricas iterando tenants

Padrão: nome em verbo no infinitivo terminando em `Service`, construtor com `keyword args`, método público único `#call`. Sem callbacks em services.

### Views

- Tailwind utility classes. Sem CSS custom novo sem aprovação.
- **Não use classes arbitrárias do Tailwind** (`min-h-[600px]`, `bg-[#abc]`) sem confirmar que a v4 compila — em caso de dúvida, use `style="..."` inline ou crie um utility no `app/assets/tailwind/application.css`.
- Layouts disponíveis:
  - `layouts/application.html.erb` — default, sidebar tenant aparece se logado e em tenant
  - `layouts/admin.html.erb` — admin master
  - `layouts/devise.html.erb` — telas de login/recuperação
- Flash messages renderizam no layout (`notice`, `alert`). Não duplique em views.

### JavaScript

- **Stimulus controllers** em `app/javascript/controllers/`, nomeados `foo_controller.js`. Auto-carregam.
- Para libs grandes (FullCalendar, etc.) que têm subpath imports: **NÃO** pin no importmap. Carregue o bundle global via `<script>` injetado dinamicamente no `connect()` do controller — ver `calendar_controller.js`.
- Para libs pequenas/limpas (Trix, Action Text): pode pinar no `config/importmap.rb`.

### Migrations

```bash
make g G='model Foo bar:string baz:integer'
make migrate
```

- Sempre `null: false, default: <valor>` para colunas que devem ter valor.
- Índices únicos com `where: "col IS NOT NULL"` se a coluna for opcional.
- Migrations rodam em todos os schemas. Use `Apartment::Migrator` se precisar de migration global-only (raríssimo).

### Models

- Enums com sintaxe `enum :role, { staff: 0, doctor: 1, ... }` (Rails 7+ kwargs).
- Validações de unicidade no model; índice DB-level também.
- Callbacks somente para invariantes do próprio modelo. Cross-model = service.
- Não polua o model com lógica de view; helpers no `ApplicationHelper` ou view-specific helpers.

### Auth & Authz

- Auth: Devise no `User`. Cadastro público está **desabilitado** (`skip: [:registrations]` em routes).
- Authz: Pundit. `Admin::BaseController` e `TenantBaseController` já fazem gating coarse-grained. Para fine-grained (ex: médico só vê seus prontuários), crie `app/policies/<model>_policy.rb` e use `authorize @record`.
- Roles em `User#role` (enum): `staff`, `doctor`, `owner`, `admin`. **Apenas `admin`** acessa `Admin::`.
- Roles em `Membership#role` (enum): `staff`, `doctor`, `owner`. Indica vínculo dentro da empresa.

### Convenções de commit

Semantic commit. Sem `#issue_id` (este projeto não usa o tracker Journey/jgh).

```
feat: adiciona X
fix: corrige Y
chore: bump dependência
refactor: extrai service Z
docs: ...
```

Co-author do agente quando aplicável.

### Push

Push é feito com a conta GitHub `brimes` (não `gruppy-brunolima` que é o default). Comando:
```
gh auth switch -u brimes && git push && gh auth switch -u gruppy-brunolima
```
(O usuário não pediu para automatizar via `.git/config remote` — manter assim.)

## O que NÃO fazer

- ❌ Criar foreign key cross-schema (tenant → public).
- ❌ Usar `Apartment::Tenant.process` (não existe na 3.x).
- ❌ Cadastro público de usuários via Devise registerable — desabilitado intencionalmente.
- ❌ Editar `MedicalRecord` após `sign!` — controller bloqueia e existe `MedicalRecordVersion` para snapshot.
- ❌ Validar permissões inline em controllers — use Pundit policies.
- ❌ Subir migrations destrutivas em tenants existentes sem checar `Company.count`.

## Documentação adicional

- `docs/ARCHITECTURE.md` — diagrama de domínio, decisões
- `docs/CONVENTIONS.md` — padrões de código mais detalhados
- `README.md` — setup local
- `Makefile` — comandos do dia-a-dia

## Estado atual

- Fase 0 — Bootstrap ✅
- Fase 1 — Auth + tenancy + admin master ✅
- Fase 2 — Doctor/Employee/Patient CRUD + invite ✅
- Fase 3 — Appointment + FullCalendar ✅
- Fase 4 — Prontuário (Action Text) + histórico + assinatura ✅
- Fase 5 — Admin dashboard cross-tenant ✅
- Fase 6 — UI refinement, testes, K8s/Helm 🚧 (pendente)
