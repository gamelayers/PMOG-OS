class CreateUserSecrets < ActiveRecord::Migration
  def self.up
    create_table :user_secrets do |t|
      t.string :user_id, :limit => 36
      t.integer :secret_question_id
      t.string :answer
      t.timestamps
    end
  end

  def self.down
    drop_table :user_secrets
  end
end
