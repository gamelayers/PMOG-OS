class RenamePmogPreferencesToTheNethernet < ActiveRecord::Migration
  def self.up
    execute("UPDATE preferences SET name = 'The Nethernet Portal Content Quality Threshold' WHERE name = 'PMOG Portal Content Quality Threshold'")
    execute("UPDATE preferences SET name = 'The Nethernet Mission Content Quality Threshold' WHERE name = 'PMOG Mission Content Quality Threshold'")
    execute("UPDATE preferences SET name = 'Periodic Updates on The Nethernet' WHERE name = 'Periodic Updates on PMOG'")
  end

  def self.down
    execute("UPDATE preferences SET name = 'PMOG Portal Content Quality Threshold' WHERE name = 'The Nethernet Portal Content Quality Threshold'")
    execute("UPDATE preferences SET name = 'PMOG Mission Content Quality Threshold' WHERE name = 'The Nethernet Mission Content Quality Threshold'")
    execute("UPDATE preferences SET name = 'Periodic Updates on PMOG' WHERE name = 'Periodic Updates on The Nethernet'")
  end
end
