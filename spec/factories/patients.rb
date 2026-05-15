FactoryBot.define do
  factory :patient do
    name { "MyString" }
    cpf { "MyString" }
    birthdate { "2026-05-15" }
    phone { "MyString" }
    email { "MyString" }
    notes { "MyText" }
  end
end
