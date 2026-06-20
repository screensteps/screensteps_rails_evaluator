FactoryBot.define do
  factory :manual do
    sequence(:title) { |n| "Manual #{n}" }

    account { default_account }
  end
end
