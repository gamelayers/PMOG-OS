# Changes the way schema_dumper writes the schema.rb file for tables that override
# the default integer, auto-increment ID column in favor of a 36 character uuid string.
module ActiveRecord
  class SchemaDumper
    
	# Overrides the default table method
    def table(table, stream)
        columns = @connection.columns(table)
        begin
          tbl = StringIO.new

          if @connection.respond_to?(:pk_and_sequence_for)
            pk, pk_seq = @connection.pk_and_sequence_for(table)
          end
          pk ||= 'id'

          tbl.print "  create_table #{table.inspect}"
          if columns.detect { |c| c.name == pk && c.type == :integer }
            skip_pk = true
            if pk != 'id'
              tbl.print %Q(, :primary_key => "#{pk}")
            end
          else
            skip_pk = false
            tbl.print ", :id => false"
          end
          tbl.print ", :force => true"
          tbl.puts " do |t|"

          column_specs = columns.map do |column|
            raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
            next if column.name == pk && skip_pk
            spec = {}
            spec[:name]      = column.name.inspect
            spec[:type]      = column.type.to_s
            spec[:limit]     = column.limit.inspect if column.limit != @types[column.type][:limit] && column.type != :decimal
            spec[:precision] = column.precision.inspect if !column.precision.nil?
            spec[:scale]     = column.scale.inspect if !column.scale.nil?
            spec[:null]      = 'false' if !column.null
            spec[:default]   = default_string(column.default) if !column.default.nil?
            (spec.keys - [:name, :type]).each{ |k| spec[k].insert(0, "#{k.inspect} => ")}
            spec
          end.compact

          # find all migration keys used in this table
          keys = [:name, :limit, :precision, :scale, :default, :null] & column_specs.map(&:keys).flatten

          # figure out the lengths for each column based on above keys
          lengths = keys.map{ |key| column_specs.map{ |spec| spec[key] ? spec[key].length + 2 : 0 }.max }

          # the string we're going to sprintf our values against, with standardized column widths
          format_string = lengths.map{ |len| "%-#{len}s" }

          # find the max length for the 'type' column, which is special
          type_length = column_specs.map{ |column| column[:type].length }.max

          # add column type definition to our format string
          format_string.unshift "    t.%-#{type_length}s "

          format_string *= ''

          column_specs.each do |colspec|
            values = keys.zip(lengths).map{ |key, len| colspec.key?(key) ? colspec[key] + ", " : " " * len }
            values.unshift colspec[:type]
            tbl.print((format_string % values).gsub(/,\s*$/, ''))
            tbl.puts
          end

          tbl.puts "  end"
          tbl.puts
          
          indexes(table, tbl)

          tbl.rewind
          stream.print tbl.read
        rescue => e
          stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
          stream.puts "#   #{e.message}"
          stream.puts
        end
        
        stream
      end

    
  end
end