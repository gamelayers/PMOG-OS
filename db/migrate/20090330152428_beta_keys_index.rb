class BetaKeysIndex < ActiveRecord::Migration
  def self.up
    begin
      execute "alter table beta_keys add index index_beta_keys_on_key(key)"
    rescue
      # Index already exists as EY created it on the production servers for us
    end
  end

  def self.down
    execute "alter table beta_keys drop index index_beta_keys_on_key"
  end
end
