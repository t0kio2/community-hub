class CreateUserRefreshTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :user_refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :device_id
      t.string :device_name
      t.bigint :replaced_by_token_id
      t.datetime :expired_at, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :user_refresh_tokens, :token_digest, unique: true
    add_index :user_refresh_tokens, [:user_id, :device_id], unique: true
    add_index :user_refresh_tokens, :expired_at
    add_index :user_refresh_tokens, :revoked_at
    add_index :user_refresh_tokens, :replaced_by_token_id
    add_foreign_key :user_refresh_tokens, :user_refresh_tokens, column: :replaced_by_token_id
  end
end
