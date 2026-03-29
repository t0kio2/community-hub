class CreateUserRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :user_refresh_tokens do |t|
      t.references :account, null: false, foreign_key: true
      t.string :token_digest
      t.string :device_id
      t.string :device_name
      t.string :user_agent
      t.string :last_used_ip
      t.datetime :expired_at
      t.datetime :revoked_at
      t.datetime :last_used_at

      t.timestamps
    end
    add_index :user_refresh_tokens, :token_digest
  end
end
