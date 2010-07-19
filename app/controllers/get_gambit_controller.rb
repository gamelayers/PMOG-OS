#ocid - unique click identifier
#uid - your user's unique ID passed when the Gambit ad panel was created
#amount (int) - amount of currency earned
#time - unix timestamp for the transaction
#oid - offer ID. Use this for your own tracking.
#title - offer title
#subid1
#subid2
#subid3
#sig - a md5 hash of the concatenation of the uid,
#pending stupid flag they send to say that this might not be good, but they never
# will tell us if it's bad. Just accept all as good for now, we can fix later if
# there are problems

require 'digest/md5'

class GetGambitController < ApplicationController
    #before_filter :check_is_gambit?
    skip_before_filter :login_required

    OK = 'OK'
    RESEND = 'ERROR:RESEND'
    FATAL_ERROR = 'ERROR:FATAL'

    GAMBIT_KEYS = :ocid, :uid, :amount, :time, :oid, :title, :subid1, :subid2, :subid3, :sig, :pending, :ip

    class NotValidGambitIPException < Exception
    end

    def create
      params['ip'] = @remote_ip

      gambit_hash = HashWithIndifferentAccess.new
      GAMBIT_KEYS.each { |x|
        gambit_hash[x] = params[x] if !params[x].nil?
      }

      gambit = Gambit.find(:first, :conditions => [ "ocid = ?", gambit_hash[:ocid]], :order => 'created_at DESC')
      if (!IsDevelopment and gambit != nil and gambit.completed_at != nil) # already processed it, so ignore it, PENDING?
        render :text => OK and return
      end

      gambit = Gambit.create(gambit_hash)  # gambit log

      raise NotValidGambitIPException if !check_is_gambit?(gambit_hash)

      # Will probably need to refactor this once we
      # add a second payment system.


      begin
        user = User.find(unmunge(gambit_hash[:uid]))

        #puts "USER: #{user}"
        Payment.credit(user, gambit_hash[:amount], @remote_ip, gambit)

        render :text => OK and return

      rescue ActiveRecord::RecordNotFound => rnf
        render :text => FATAL_ERROR
        raise

      rescue Exception => e:
        render :text => RESEND
        raise
      end

      render :text => RESEND
    end

    protected

    def check_is_gambit?(params)
      # make sure this is really gambit
      #Gambit range is 72.52.114.240-247, this is good enough
      return (@remote_ip['72.52.114.24'] != nil and is_valid_sig?)
    end

    def is_valid_sig?
      processor = Processor.find_by_name(Processor.get_name(Gambit::GAMBIT)) # should cache this

      Digest::MD5.hexdigest(params[:uid] + params[:amount] + params[:time] + params[:oid] + processor.secret_key) == params[:sig]
    end

    def unmunge(munged)
      munged[0,8] + '-' + munged[8,4] + "-" + munged[12,4] + '-' + munged[16,4] + '-' + munged[20,munged.length]
    end
end
