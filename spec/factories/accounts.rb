def default_account
  Account.find_by(domain: 'default') || create(:account, with_owner: false, domain: 'default')
end

FactoryBot.define do
  factory :account do
    transient do
      with_owner { true }
    end

    sequence(:domain) { |n| "test#{n}" }
    public_id { SecureRandom.uuid.upcase }
    company { 'My Company' }
    status { 'active' }

    after(:create) do |account, evaluator|
      if account.owner.blank? && evaluator.with_owner
        user = create(:user, role: 'admin', account: account)
        account.update_column(:owner_id, user.id) # rubocop:disable Rails/SkipsModelValidations
      end
    end
  end
end
