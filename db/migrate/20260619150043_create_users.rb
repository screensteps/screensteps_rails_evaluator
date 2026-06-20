class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.integer 'account_id'
      t.datetime 'activated_at', precision: nil
      t.json 'data'
      t.boolean 'deactivated', default: false, null: false
      t.datetime 'discarded_at'
      t.string 'email'
      t.string 'encrypted_password', default: ''
      t.string 'first_name'
      t.boolean 'invite_pending', default: false, null: false
      t.datetime 'last_login', precision: nil
      t.string 'last_name'
      t.string 'login'
      t.virtual 'name', type: :string,
                        as: "(case when first_name is not null and last_name is not null then first_name || ' ' || last_name else coalesce(first_name, last_name, login) end)", stored: true
      t.string 'public_id'
      t.string 'role'
      t.string 'time_zone'
      t.timestamps

      t.index %w[account_id last_name first_name]
      t.index %w[account_id role]
      t.index %w[discarded_at deactivated invite_pending account_id]
      t.index %w[email account_id], unique: true
      t.index %w[login account_id], unique: true
      t.index ['public_id'], unique: true
      t.index %w[role discarded_at deactivated invite_pending account_id]
    end
  end
end
