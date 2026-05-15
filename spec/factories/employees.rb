FactoryBot.define do
  factory :employee do
    name { "MyString" }
    job_title { "MyString" }
    user_id { 1 }
    active { false }
  end
end
