module MessageErrors
  class MessageError < PMOG::PMOGError;end
  
  class EmptyBodyError < MessageError
    def default
      "Please provide a message to send."
    end
  end
  
  class EmptyRecipientError < MessageError
    def default
      "Please add at least one @recipient but not more than five."
    end
  end
  
  class InsufficientDpError < MessageError    
    def default
      "Sorry, you don't have enough datapoints to send messages to your recipient list."
    end
  end
  
  class TooManyRecipientsError < MessageError
    def default
      "You have specified too many recipients. You may only mail five players at once."
    end
  end
  
  class RecipientAlreadyPlaying < MessageError
    def default
      "That email address is already playing PMOG."
    end
  end
end