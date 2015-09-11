class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :uid
      t.string :full_name
      t.string :username
      t.date :followed_at
      t.date :unfollowed_at
      t.integer :follower_count
      t.boolean :influential, default: false
      t.boolean :follows_me, default: false
      t.boolean :followed_by_me, default: false
      t.boolean :manually_followed, default: false
      t.timestamps null: false
    end
  end
end
