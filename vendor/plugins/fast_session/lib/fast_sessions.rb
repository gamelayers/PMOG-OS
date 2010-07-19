class CGI
  class Session
    class ActiveRecordStore
      class FastSessions
        # Attempt to use the master database connection, since the masochism plugin
        # wants to send the inserts/updates to the slave, when they shoud
        # go to the master. If that fails, fall back to the default connection - duncan 23/09/08
        cattr_accessor :connection
        @@connection = ActiveRecord::Base.connection


        # The table name defaults to 'fast_sessions'.
        cattr_accessor :table_name
        @@table_name = 'fast_sessions'

        # If you're going to use this module with MySQL 5.1.22+, then you'd 
        # like to set this to +true+ because it will provide you with consecutive
        # data inserts in InnoDB. Another cases when you'd like to use it is when
        # your MySQL server is I/O bound now and you do not want to add random I/O
        # because of randomized primary key.
        cattr_accessor :use_auto_increment
        @@use_auto_increment = false

        # If you do not like to loose old sessions created with default AR sessions plugin,
        # set this to +true+ and all session reads will fall back to old sessions reads if
        # some session_id was not found in fast_sessions table
        cattr_accessor :fallback_to_old_table
        @@fallback_to_old_table = false

        # Old AR sessions table name defaults to 'sessions'.
        cattr_accessor :old_table_name
        @@old_table_name = 'sessions'

        # Look up a session by id and create session object from found data
        # If record has not been found, we'll create a fake session with empty data
        # to prevent AR from creation of a new session record.
        def self.find_by_session_id(session_id)
          rec = @@connection.select_one <<-end_sql, 'Load Session'
            SELECT data
              FROM #{@@table_name} 
             WHERE session_id_crc = CRC32(#{@@connection.quote(session_id)})
               AND session_id = #{@@connection.quote(session_id)}
          end_sql
          
          if !rec && @@fallback_to_old_table
            rec = @@connection.select_one <<-end_sql, 'Load Session (old)'
              SELECT data
                FROM #{@@old_table_name} 
               WHERE session_id = #{@@connection.quote(session_id)}
            end_sql
          end
          
          session_data = rec ? rec['data'] : nil
          new(:session_id => session_id, :marshaled_data => session_data)
        end

        # Marshaling functions
        def self.marshal(data)   Base64.encode64(Marshal.dump(data)) if data end
        def self.unmarshal(data) Marshal.load(Base64.decode64(data)) if data end

        # Create table for this session storage
        def self.create_table!
          # If user asked us to use auto_increment, 
          # then we need to add this field to the table
          if @@use_auto_increment
            autoinc_id_field = "id INT(10) UNSIGNED NOT NULL auto_increment,"
            autoinc_primary_key = "PRIMARY KEY(id),"
          else
            autoinc_primary_key = autoinc_id_field = ""
          end
          
          # Creating table
          @@connection.execute <<-end_sql
            CREATE TABLE #{table_name} (
              #{autoinc_id_field}
              session_id_crc INT(10) UNSIGNED NOT NULL,
              session_id VARCHAR(32) NOT NULL,
              updated_at TIMESTAMP NOT NULL,
              data TEXT,
              #{autoinc_primary_key}
              UNIQUE KEY `session_id` (session_id_crc, session_id),
              KEY `updated_at` (`updated_at`)
            ) ENGINE=InnoDB;
          end_sql
        end

        # Drop session storage table
        def self.drop_table!
          @@connection.execute "DROP TABLE #{table_name}"
        end

        # Delete old sessions from the storage table
        # _seconds_ parameter specifies how long you want to store your sessions.
        # By default, sessions stored for 1 week
        def self.delete_old!(seconds = 604800)
          @@connection.execute "DELETE FROM #{table_name} WHERE updated_at < UNIX_TIMESTAMP(NOW()) - #{seconds}"
        end

        #-----------------------------------------------------------------------
        attr_reader :session_id
        attr_writer :data

        # Create session object from provided data (marshaled or not)
        def initialize(attributes)
          @session_id = attributes[:session_id]
          @data = attributes[:data]
          @marshaled_data = attributes[:marshaled_data] || self.class.marshal({})
        end

        # Lazy-unmarshal session state.
        def data
          @data ||= self.class.unmarshal(@marshaled_data)
        end

        # Create/update session if session data has been changed during a request processing
        def save
          return unless should_save_session?
          
          # Marshal data before saving
          marshaled_data = self.class.marshal(data)

          # Save data to DB
          @@connection.update <<-end_sql, 'Create/Update session'
            INSERT INTO #{@@table_name} SET
              data = #{@@connection.quote(marshaled_data)}, 
              updated_at = NOW(),
              session_id_crc = CRC32(#{@@connection.quote(session_id)}),
              session_id = #{@@connection.quote(session_id)}
            ON DUPLICATE KEY UPDATE
              data = #{@@connection.quote(marshaled_data)}, 
              updated_at = NOW()
          end_sql
        end

        # Destroy current session record
        def destroy
          @@connection.delete <<-end_sql, 'Destroy session'
            DELETE FROM #{@@table_name}
             WHERE session_id_crc = CRC32(#{@@connection.quote(session_id)})
               AND session_id = #{@@connection.quote(session_id)}
          end_sql
        end

      private
  
        # Returns true if session should be saved, which is 
        # when session data has been changed and user did not
        # requested skipping data saving
        def should_save_session?
          # Do not save data if user asked to skip saving or force saving it was requested
          force_saving = data.delete(:force_session_saving)
          skip_saving = data.delete(:skip_session_saving)
          
          # Forced saving has higher priority
          return true if force_saving
          return false if skip_saving
    
          # Handle a special case (original session was empty and new session has only an empty flash)
          if (self.class.unmarshal(@marshaled_data) == {})
            return false if data.empty? || (data.keys == ["flash"] && data["flash"].empty?)
          end

          # We can update data if something changed in session hash
          self.class.marshal(data) != @marshaled_data
        end

      end
    end
  end
end
