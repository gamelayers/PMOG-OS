#---
# Excerpted from "Advanced Rails Recipes",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/fr_arr for more book information.
#---
class LabelFormBuilder < ActionView::Helpers::FormBuilder
  
  helpers = field_helpers +
           %w(date_select datetime_select time_select) +
           %w(collection_select select country_select time_zone_select) -
           %w(hidden_field label fields_for)

  helpers.each do |name|
    define_method(name) do |field, *args|
      options = args.last.is_a?(Hash) ? args.pop : {}
      @template.content_tag(:p, label(field) + super)
    end
  end
end