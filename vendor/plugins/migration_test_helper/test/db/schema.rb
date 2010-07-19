ActiveRecord::Schema.define(:version => 1) do
  create_table "dogs", :force => true do |t|
    t.column "tail", :string, :default => 'top dog', :limit => 187
  end
  add_index :dogs, :tail, :name => 'index_tail_on_dogs'
end
