# Convenções de código — Mali-D

Padrões a seguir em qualquer mudança. Quando algo aqui não couber, abra discussão antes
de divergir.

## Geral

- Ruby idiomático, sem hype. Sem metaprogramação onde método simples resolve.
- Sem comentários redundantes (o que o código diz). Comente o **porquê**, não o **o quê**.
- Arquivos curtos. Se um controller passou de 150 linhas, extraia service ou helper.

## Estrutura de diretórios

```
app/
├── controllers/
│   ├── application_controller.rb       # base de TUDO (autenticação)
│   ├── admin/                           # área admin master (subdomínio app)
│   │   ├── base_controller.rb           # gate de admin
│   │   └── ...
│   ├── tenant_base_controller.rb        # gate de tenant
│   └── <recurso>_controller.rb          # CRUDs do tenant
├── models/
│   ├── user.rb, company.rb, membership.rb   # globais (public schema)
│   └── doctor.rb, patient.rb, ...           # tenant
├── policies/                            # Pundit (1 por modelo quando necessário)
├── services/                            # lógica multi-modelo / multi-tenant
├── views/
│   ├── layouts/
│   │   ├── application.html.erb         # default
│   │   ├── admin.html.erb               # admin master
│   │   └── devise.html.erb              # login
│   ├── admin/                           # views da área admin
│   └── <recurso>/                       # views do tenant
└── javascript/
    └── controllers/                     # Stimulus
```

## Models

```ruby
class Doctor < ApplicationRecord
  # Constantes primeiro
  SOME_CONST = 10

  # Enums
  enum :status, { active: 0, inactive: 1 }

  # Associações
  has_many :appointments, dependent: :restrict_with_error

  # Validações
  validates :name, presence: true
  validates :crm, presence: true, uniqueness: true

  # Scopes
  scope :active, -> { where(status: :active) }

  # Métodos públicos
  def display_name
    "Dr(a). #{name}"
  end

  private

  def some_internal_thing
    # ...
  end
end
```

- Não use `default_scope`.
- `dependent: :destroy` ou `:restrict_with_error` sempre que houver `has_many`.
- Para FKs cross-schema (tenant → public.users), use coluna inteira **sem** `references` e busque manualmente.

## Controllers

```ruby
class DoctorsController < TenantBaseController
  before_action :set_doctor, only: [:show, :edit, :update, :destroy]

  def index
    @doctors = Doctor.order(:name)
  end

  def create
    @doctor = Doctor.new(doctor_params)
    if @doctor.save
      redirect_to doctor_path(@doctor), notice: "Médico cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_doctor
    @doctor = Doctor.find(params[:id])
  end

  def doctor_params
    params.require(:doctor).permit(:name, :crm, :specialty, :active)
  end
end
```

- `before_action :set_<resource>` para evitar repetição.
- Strong params em método privado.
- Status code `:unprocessable_entity` em render de falha (necessário para Turbo).
- Mensagens flash em português.

## Services

```ruby
class InviteUserService
  def initialize(email:, name:, role:, company:)
    @email = email
    @name = name
    @role = role
    @company = company
  end

  def call_and_link(tenant_record)
    # ... uma responsabilidade
  end
end

# Uso:
InviteUserService.new(email: "x@y", name: "X", role: :doctor, company: c).call_and_link(doctor)
```

- Kwargs obrigatórios.
- Um método público principal (`#call` ou nome de domínio).
- Sem `ActiveRecord::Callbacks` no service — explicite no chamador.
- Para multi-tenant: use `Apartment::Tenant.switch("public") { ... }` quando precisar bater no schema global.

## Views

- Tailwind utility classes diretamente no markup.
- Partials para reuso (`_form.html.erb`, etc.).
- `form_with model:` em vez de `form_for`.
- Evite ERB complexa — extraia helper.
- Botões padrão:
  ```erb
  <%= link_to "Voltar", path, class: "bg-gray-200 px-3 py-2 rounded" %>
  <%= link_to "Ação primária", path, class: "bg-blue-600 text-white px-3 py-2 rounded" %>
  <%= button_to "Remover", path, method: :delete,
        data: { turbo_confirm: "Remover?" },
        class: "bg-red-600 text-white px-3 py-2 rounded" %>
  ```

## Stimulus

```js
// app/javascript/controllers/foo_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["output"]

  connect() { /* ... */ }
  disconnect() { /* cleanup */ }
}
```

- Sempre implemente `disconnect()` se `connect()` alocou recursos (timers, listeners, libs externas).
- Para libs grandes ou com subpath imports problemáticos: carregue via `<script>` em `connect()`.

## Migrations

```ruby
class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :doctor, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.integer  :status, null: false, default: 0
      t.text     :notes
      t.timestamps
    end
    add_index :appointments, [:doctor_id, :starts_at]
  end
end
```

- `null: false, default: <valor>` para colunas obrigatórias.
- Índices compostos quando o query pattern justifica.
- `add_index ..., where: "col IS NOT NULL"` para uniques opcionais.

## Testes (a serem escritos)

```ruby
# spec/models/appointment_spec.rb
require "rails_helper"

RSpec.describe Appointment, type: :model do
  describe "validações" do
    it "rejeita conflito de horário do mesmo médico" do
      doctor = create(:doctor)
      patient = create(:patient)
      create(:appointment, doctor: doctor, starts_at: 1.hour.from_now, ends_at: 2.hours.from_now)
      conflict = build(:appointment, doctor: doctor, starts_at: 90.minutes.from_now, ends_at: 3.hours.from_now)
      expect(conflict).not_to be_valid
    end
  end
end
```

- Para tests envolvendo tenant: usar `Apartment::Tenant.switch` em `before` ou helper compartilhado.
- Factories em `spec/factories/` (já criadas pelos generators).
- Request specs para fluxos críticos (login, criar consulta, assinar prontuário).

## Git

- Branch principal: `main`.
- Commits semânticos: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`.
- Mensagens em **português** (front-end + domínio é PT-BR).
- Sem referência a issue tracker (este repo não usa).
- Push: precisa trocar para conta `brimes` (`gh auth switch -u brimes`).

## Variáveis de ambiente

Todas em `.env.example`. Quem adicionar nova var, atualiza o exemplo na mesma PR.

| Var              | Default                | Função                          |
|------------------|------------------------|---------------------------------|
| DB_HOST          | localhost              | host postgres                   |
| DB_USER          | postgres               | usuário                         |
| DB_PASSWORD      | postgres               | senha                           |
| ADMIN_EMAIL      | admin@mali-d.local     | seed do admin master            |
| ADMIN_PASSWORD   | changeme123            | senha do admin master           |
| RAILS_MAX_THREADS| 5                      | pool de threads                 |
