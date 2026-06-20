class CreateSpaces < ActiveRecord::Migration[8.1]
  def change
    create_table :spaces do |t|
      t.integer 'account_id'
      t.boolean 'allow_ratings', default: false, null: false
      t.json 'data'
      t.text 'description'
      t.string 'domain'
      t.boolean 'hide_from_list', default: false, null: false
      t.string 'host_mapping'
      t.string 'language', limit: 10, default: 'en', null: false
      t.text 'message'
      t.string 'meta_description'
      t.string 'meta_title'
      t.string 'permalink', limit: 50
      t.boolean 'protected', default: true, null: false
      t.string 'theme', default: 'alpha', null: false
      t.string 'title'
      t.timestamps

      t.index ['account_id']
      t.index ['host_mapping'], unique: true
      t.index ['language']
      t.index %w[permalink account_id], unique: true
    end
  end
end
