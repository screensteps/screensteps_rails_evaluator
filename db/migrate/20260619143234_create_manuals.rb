class CreateManuals < ActiveRecord::Migration[8.1]
  def change
    create_table :manuals do |t|
      t.boolean 'allow_comments', default: true, null: false
      t.integer 'creator_id'
      t.datetime 'discarded_at', precision: nil
      t.boolean 'draft', default: false, null: false
      t.string 'icon', default: 'book'
      t.boolean 'internal', default: false, null: false
      t.text 'message'
      t.string 'meta_description'
      t.string 'meta_title'
      t.string 'permalink', limit: 50
      t.string 'public_title'
      t.boolean 'restricted', default: false, null: false
      t.integer 'space_id', null: false
      t.string 'title'
      t.string 'toc_description'
      t.string 'uuid'
      t.boolean 'visible', default: false, null: false
      t.timestamps

      t.index %w[space_id internal permalink]
      t.index ['creator_id']
      t.index ['restricted']
      t.index ['space_id']
      t.index ['uuid'], unique: true
    end
  end
end
