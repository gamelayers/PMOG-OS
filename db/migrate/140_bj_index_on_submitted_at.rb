class BjIndexOnSubmittedAt < ActiveRecord::Migration
  def self.up
    add_index :bj_job, :submitted_at
  end

  def self.down
    remove_index :bj_job, :submitted_at
  end
end
