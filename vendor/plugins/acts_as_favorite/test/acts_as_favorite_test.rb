require File.join(File.dirname(__FILE__), 'test_helper')

class User < ActiveRecord::Base
  acts_as_favorite_user
  acts_as_favorite
end

class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :favorable, :polymorphic => true
end

class Book < ActiveRecord::Base
  acts_as_favorite
end

class Drink < ActiveRecord::Base
  acts_as_favorite
end

class ActsAsFavoriteTest < Test::Unit::TestCase
  fixtures :users, :books, :drinks, :favorites
  
  def test_user_should_have_favorites
    assert users(:josh).has_favorites?
  end
  
  def test_should_create_favorite
    assert_difference users(:james).favorites, :count do
      users(:james).favorite! books(:agile)
    end
  end
  
  def test_dynamic_counter_should_return_true
    assert users(:josh).has_favorite_books?
  end
  
  def test_should_return_false_with_no_favorite_books
    assert_equal false, users(:george).has_favorite_books?
  end
  
  def test_should_add_items_to_favorites
    assert_difference Favorite, :count do
      users(:james).favorite! drinks(:wine)
      assert users(:james).favorited?(drinks(:wine))
    end
  end
  
  def test_should_remove_from_favorites
    assert_difference users(:josh).favorites, :count, -1 do
      users(:josh).unfavorite! drinks(:beer)
    end
  end
  
  def test_should_return_users_with_specified_favorite
    assert books(:ruby).fans.include?(users(:josh))
  end
  
  def test_favoriting_users_works
    assert_equal 1, users(:josh).favorite_users.size
    assert_equal users(:james), users(:josh).favorite_users.first
    
    assert users(:josh).favorite! users(:george)
    assert_equal 2, users(:josh).favorite_users.size
  end
  
  def test_favoriting_count_works
    assert_equal 1, users(:josh).favorite_users.size
    assert_equal 1, users(:josh).favorite_users_count
  end  
  
  def test_should_add_and_remove_favorites
    Book.find(:all, :include => :favorings,
              :conditions => ['favorites.user_id = ? AND favorites.favorable_type = ?', 
                              1, 'Book' ] )
    
  
    assert_difference users(:george).favorites, :count, 3 do
      users(:george).favorite! books(:agile)
      users(:george).favorite! books(:ruby)
      users(:george).favorite! books(:rails)
    end
        
    assert_equal 3, users(:george).favorites.size
    
    assert_equal 3, users(:george).favorite_books.size
  
    assert_difference users(:george).favorites, :count, -2 do
      users(:george).unfavorite! books(:agile)
      users(:george).unfavorite! books(:ruby)
    end
    assert_equal 1, users(:george).favorites.size
    assert users(:george).favorite_books.size, 1
  
  end

end
