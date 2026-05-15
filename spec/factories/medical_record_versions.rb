FactoryBot.define do
  factory :medical_record_version do
    medical_record { nil }
    body { "MyText" }
    author_id { 1 }
    created_at_snapshot { "2026-05-15 18:37:58" }
  end
end
