module QueryTrace
  def self.append_features(klass)
    super
    klass.class_eval do
      unless method_defined?(:log_info_without_trace)
        alias_method :log_info_without_trace, :log_info
        alias_method :log_info, :log_info_with_trace
      end
    end
    klass.class_eval %(
      def row_even
        @@row_even
      end
    )
  end
  
  def log_info_with_trace(sql, name, runtime)
    log_info_without_trace(sql, name, runtime)
    
    if @config[:query_trace]
      return unless @logger and @logger.debug?
      return if / Columns$/ =~ name

      trace = clean_trace(caller[2..-1])
      @logger.debug(format_trace(trace))
    end
  end
  
  def format_trace(trace)
    if ActiveRecord::Base.colorize_logging
      if row_even
        message_color = "37;40"
      else
        message_color = "37;40"
      end
      trace.collect{|t| "    \e[#{message_color}m#{t}\e[0m"}.join("\n")
    else
      trace.join("\n    ")
    end
  end
  
  VENDOR_RAILS_REGEXP = %r(([\\/:])vendor\1rails\1)
  def clean_trace(trace)
    return trace unless defined?(RAILS_ROOT)
    
    trace = trace.select {|t| /#{Regexp.escape(File.expand_path(RAILS_ROOT))}/ =~ t}
    trace.reject! {|t| VENDOR_RAILS_REGEXP =~ t}
    trace.map! {|t| t.gsub(RAILS_ROOT + '/', '')}
    trace.reject! { |t| t.match(/vendor\/plugins\/footnotes\/lib\/notes\/queries_note.rb/) }
    trace.uniq!
    trace[0,3]
  end
end
