class PmogClassImages < ActiveRecord::Migration
  @associations = [ 'Benefactor', 'Seer', 'Destroyers', 'Pathmakers', 'Vigilantes', 'Riveters', 'Grenadiers', 'Bedouins' ]

  def self.up
    @associations.each do |assoc|
      pmog_class = PmogClass.find( :first, :conditions => { :name => assoc } )
      pmog_class.large_image = "/images/icons/associations/" + assoc.downcase + ".jpg"
      pmog_class.save
    end
  end

  def self.down
    # These image resources only exist in the new locations now
    # Migrating .down and breaking the links would serve no purpose, and this query was busted to begin with

    #@associations.each do |assoc|
    #  pmog_class = PmogClass.find( :first, :conditions => { :name => assoc } )
    #  pmog_class.large_image = "/images/icons/classes/" + assoc.downcase + ".jpg"
    #  pmog_class.save
    #end
  end
end
