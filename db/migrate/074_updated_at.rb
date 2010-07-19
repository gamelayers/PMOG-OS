class UpdatedAt < ActiveRecord::Migration
  
  @@tables = [ 
      'bird_bots',
      'branches',
      'events',
      'levels',
      'npcs',
      'pmog_classes',
      'tags',
      'tools'
  ]

  def self.up
    @@tables.each do |table|
      model = table.classify.constantize
      add_column table.to_sym, :created_at, :datetime unless model.column_names.include? 'created_at'
      add_column table.to_sym, :updated_at, :datetime unless model.column_names.include? 'updated_at'
    end
  end

  def self.down
    # No real need to migrate backwards from this migration
  end
end
