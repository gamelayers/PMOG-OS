class FixUsersWithNoDob < ActiveRecord::Migration
  def self.up
    User.all do |user|
      if user.date_of_birth.nil?
        user.date_of_birth = 90.years.ago
        user.save
      end
    end
  end

  def self.down
  end
end
