FactoryBot.define do
  factory :doctor do
    name { "MyString" }
    crm { "MyString" }
    specialty { "MyString" }
    user_id { 1 }
    active { false }
  end
end
