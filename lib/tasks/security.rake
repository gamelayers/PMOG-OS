namespace :security do
  desc "Check models for associations open for mass assignment."
  task( :audit_mass_assignment => :environment ) do
    report = []
    Dir.glob("app/models/*rb") { |f|
        f.match(/\/([a-z_]+).rb/)
        classname = $1.camelize
        klass = Kernel.const_get classname
        page = { :name => klass, :items => [] }
        
        if klass.methods.include?('superclass') && klass.superclass == ActiveRecord::Base
          associations = []
          klass.reflect_on_all_associations.collect do |x|
            case x.macro.to_s
              when 'has_many': associations << x.name.to_s.tableize
              when 'belongs_to', 'has_one': associations << x.name.to_s.tableize.singularize
            end
          end
          associations.sort!
          attrs = klass.attr_accessible.sort + klass.attr_protected.sort
          associations.each do |a|
            page[:items] << ":#{a}" if attr_vulnerable(a,klass,attrs)
          end
          report << page unless page[:items].empty?
        end
    }
    generate_report(report)
  end
end

private
def attr_vulnerable(a, klass, attrs)
  vulnerable = false
  
  # If the accessible array is not empty then it either explicitly allows this association to
  # be mass-assigned or it protects against mass-assignment because it is not specified in the
  # list of available attributes. In either case we should not consider this attribute 
  # vulnerable.
  return false  if !klass.attr_accessible.empty?
  
  # This attribute is protected because it appears in the list of protected attributes
  return false if klass.attr_protected.include?(a)
  
  # The attribute is vulnerable to mass-assignment.
  true
end

def generate_report(report)
  if report.empty?
    puts %{

Congratulations, none of your model's assocations appear to susceptible to mass-assignment.

}
  else
    puts %{
WARNING #{report.size}, model(s) were found susceptible to mass assignment.
-------------------------------------------------------------------
#{affected_models(report)}
} 
  end
end

def affected_models(report)
  out = ''
  report.each_with_index do |page, index|
    out << format_page(page,index+1)
  end
  out
end

def format_page(page, number)
  out = %{
  #{number}. #{page[:name]} (#{page[:items].size}) attributes
  Possible Fix:
}
  if !page[:name].attr_protected.empty?
    out << %{  Add these keys to your attr_protected method:
}
  else
    out << "  attr_protected"
  end
  out << "  #{page[:items].join(', ')}
"
end