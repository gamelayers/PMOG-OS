class AwsmattacksIndexWork < ActiveRecord::Migration
  def self.up
    execute("alter table awsmattacks drop index idx_awsm_in_user_id_created_at, drop index idx_awsm_in_user_id_context_created_at")
    add_index :awsmattacks, [:user_id, :created_at, :context]
  end

  def self.down
    remove_index :awsmattacks, [:user_id, :created_at, :context]
    execute("CREATE INDEX idx_awsm_in_user_id_created_at ON awsmattacks (user_id, created_at)")
    execute("CREATE INDEX idx_awsm_in_user_id_context_created_at ON awsmattacks (user_id, context, created_at)")
  end
end
