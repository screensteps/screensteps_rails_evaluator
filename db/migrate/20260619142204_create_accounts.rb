class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.datetime 'activated_at', precision: nil
      t.boolean 'api_enabled', default: false, null: false
      t.string 'api_key', limit: 16
      t.datetime 'canceled_at', precision: nil
      t.string 'company'
      t.integer 'company_space_id'
      t.json 'data'
      t.string 'date_format'
      t.string 'domain'
      t.boolean 'flagged_for_deletion', default: false, null: false
      t.datetime 'last_login', precision: nil
      t.integer 'owner_id'
      t.string 'public_id', limit: 40
      t.date 'scheduled_deletion_at'
      t.string 'status', default: 'inactive'
      t.string 'time_format'
      t.string 'time_zone'
      t.timestamps

      t.index ['api_key'], unique: true
      t.index ['domain']
      t.index ['public_id'], unique: true
      t.index ['status']
    end
  end
end
