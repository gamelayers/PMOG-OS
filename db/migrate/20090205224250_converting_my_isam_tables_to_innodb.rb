class ConvertingMyIsamTablesToInnodb < ActiveRecord::Migration
  def self.up
    execute("ALTER TABLE assets ENGINE = InnoDB")
    execute("ALTER TABLE sessions ENGINE = InnoDB")
  end

  def self.down
    # No real need to migrate down from this
  end
end
