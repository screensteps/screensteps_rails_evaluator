FactoryBot.define do
  factory :user do
    account { default_account }

    first_name { 'User' }
    last_name { 'Name' }
    role { 'admin' }
    sequence(:email) { |n| "#{n}@screensteps.dev" }
    sequence(:login) { |n| "login_#{n}" }
    activated_at { Time.current }
    invite_pending { false }

    factory :root, class: 'User' do
      account { nil }
      first_name { 'Root' }
      last_name { 'User' }
      sequence(:login) { |n| "#{n}_root@screensteps.dev" }
      sequence(:email) { |n| "#{n}_root@screensteps.dev" }
      role { 'root' }
    end

    factory :admin_user do
      role { 'admin' }
      sequence(:login) { |n| "user_admin_#{n}" }
      sequence(:email) { |n| "admin_#{n}@screensteps.dev" }
    end

    factory :editor_user do
      role { 'editor' }
      sequence(:email) { |n| "editor_#{n}@screensteps.dev" }
    end

    factory :reader_user do
      sequence(:first_name) { |n| "Reader #{n}" }
      role { 'reader' }
      sequence(:email) { |n| "reader_#{n}@screensteps.dev" }
    end

    factory :api_access_user do
      first_name { 'API' }
      last_name { 'Access' }
      role { 'api access' }
      sequence(:email) { |n| "api_#{n}@screensteps.dev" }
    end
  end
end
