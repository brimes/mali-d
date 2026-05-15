FactoryBot.define do
  factory :appointment do
    doctor { nil }
    patient { nil }
    starts_at { "2026-05-15 18:37:56" }
    ends_at { "2026-05-15 18:37:56" }
    status { 1 }
    notes { "MyText" }
  end
end
