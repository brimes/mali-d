FactoryBot.define do
  factory :medical_record do
    appointment { nil }
    patient { nil }
    doctor { nil }
    vital_signs { "" }
    signed_at { "2026-05-15 18:37:57" }
    signed_by_id { 1 }
  end
end
