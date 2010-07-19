class Hoarder2Benefactor < ActiveRecord::Migration
  def self.up
    c = PmogClass.find_by_name('Hoarder')
    c.name = 'Benefactor'
    c.small_image = '/images/benefactor.jpg'
    c.large_image = '/images/icons/classes/benefactor.jpg'
    c.short_description = 'Benefactors primarily use Crates to store datapoints and tools on sites all over the internetz. Benefactors carry the torch of Order.'
    c.save
  end

  def self.down
    c = PmogClass.find_by_name('Benefactor')
    c.name = 'Hoarder'
    c.small_image = '/images/hoarder.jpg'
    c.large_image = '/images/icons/classes/hoarder.jpg'
    c.short_description = 'Hoarders primarily use Crates to store datapoints and tools on sites all over the internetz. Hoarders carry the torch of Order.'
    c.save
  end
end
