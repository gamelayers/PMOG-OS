module ActsAsFavorite

  module UserExtensions
    def self.included(recipient)
      recipient.extend(ClassMethods)
    end
    
    module ClassMethods
      def acts_as_favorite_user
        has_many :favorites
        has_many :favorables, :through => :favorites
        include ActsAsFavorite::UserExtensions::InstanceMethods
      end
    end
    
    module InstanceMethods
      def method_missing( method_sym, *args )
        if method_sym.to_s =~ Regexp.new("^favorite_(\\w+)_count")
          favorite_class = ($1).singularize.classify.constantize
          Favorite.count( :include => :user, :conditions => [ 'favorites.user_id = ? AND favorites.favorable_type = ?', 
                                                              id, favorite_class.to_s ] )
        elsif method_sym.to_s =~ Regexp.new("^favorite_(\\w+)")
          favorite_class = ($1).singularize.classify.constantize
          favorite_class.find(:all, :include => :favorings,
                              :conditions => ['favorites.user_id = ? AND favorites.favorable_type = ?', 
                                              id, favorite_class.to_s ] )
        elsif method_sym.to_s =~ Regexp.new("^has_favorite_(\\w+)\\?")
          favorite_class = ($1).singularize.classify.constantize
          Favorite.count( :include => :user, :conditions => [ 'favorites.user_id = ? AND favorites.favorable_type = ?', 
                                                              id, favorite_class.to_s ] ) != 0
        else
          super
        end
      rescue
        super
      end
      
      # Returns a polymorphic array of all user favorites 
      def all_favorites
        self.favorites.map{|f| f.favorable }
      end
            
      # Returns true/false if the provided object is a favorite of the users
      def favorited?( favorite_obj )
        favorite = get_favorite( favorite_obj )
        favorite ? self.favorites.exists?( favorite.id ) : false
      end
      
      # Sets the object as a favorite of the users
      def favorite!( favorite_obj )
        favorite = get_favorite( favorite_obj )
        if favorite.nil?
          favorite = Favorite.create( :user_id => self.id,
                                      :favorable_type => favorite_obj.class.to_s, 
                                      :favorable_id   => favorite_obj.id )
        end
        favorite
      end
      
      # Removes an object from the users favorites
      def unfavorite!( favorite_obj )
        favorite = get_favorite ( favorite_obj )
        
        if favorite
          self.favorites.delete( favorite )
          favorite_obj.favorings.delete( favorite )
          favorite.destroy
        end
      end
      
      private
      
      # Returns a favorite
      def get_favorite( favorite_obj )
        Favorite.find( :first,
                       :conditions => [ 'user_id = ? AND favorable_type = ? AND favorable_id = ?',
                                         self.id, favorite_obj.class.to_s, favorite_obj.id ] )
      end
    end
  end
  
  
  module ModelExtensions
    def self.included( recipient )
      recipient.extend( ClassMethods )
    end
    
    module ClassMethods
      def acts_as_favorite
        has_many :favorings, :as => :favorable, :class_name => 'Favorite'
        has_many :fans, :through => :favorings, :source => :user
      end      
    end
  end
end