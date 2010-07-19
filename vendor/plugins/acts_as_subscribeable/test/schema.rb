ActiveRecord::Schema.define(:version => 0) do
  create_table :articles, :force => true do |t|
    t.string        :title
    t.text          :body
    t.timestamps
  end
  
  create_table :users, :force => true do |t|
    t.string        :email
    t.timestamps
  end
end