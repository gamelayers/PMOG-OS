# This will allow us to use helpers in models or controllers.
# http://snipplr.com/view/2505/use-helpers-in-controllers-or-models/

def help
  Helper.instance
end

class Helper
  include Singleton
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::DateHelper
end
