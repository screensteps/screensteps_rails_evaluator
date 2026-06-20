FactoryBot.define do
  factory :space do
    sequence(:title) { |n| "Space #{n}" }
    account { default_account }
    domain { 'test' }

    trait :with_host_mapping do
      host_mapping { 'test.theglobe.com' }
    end

    trait :company_space do
      after(:create) do |space|
        space.account.update_attribute(:company_space, space) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
