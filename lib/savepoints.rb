module ActiveRecord
  class Base

    def self.gl_savepoint(&block)
      if Thread.current['open_transactions'] > 0
        name = ''
        alph = ['0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f']
        16.times { name << alph[rand(16)] }

        begin
          execute("SAVEPOINT #{name}")
          yield
        rescue Exception
          execute("ROLLBACK TO SAVEPOINT #{name}")
          raise
        ensure
          begin
            execute("RELEASE SAVEPOINT #{name}")
          rescue Exception # this can throw its own mysql error, theoretically, but i don't think we don't care; this is gc anyway
          end
        end
      else
        transaction(&block)
      end
    end

  end
end
