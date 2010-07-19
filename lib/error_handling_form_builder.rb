#---
# Excerpted from "Advanced Rails Recipes",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/fr_arr for more book information.
#---
class ErrorHandlingFormBuilder < ActionView::Helpers::FormBuilder

  helpers = field_helpers +
    %w(date_select datetime_select time_select collection_select) +
    %w(collection_select select country_select time_zone_select) -
    %w(label fields_for)

  helpers.each do |name|
    define_method name do |field, *args|
      options = args.detect {|argument| argument.is_a?(Hash)} || {}
      build_shell(field, options) do
        super
      end
    end
  end

  def build_shell(field, options)
    @template.capture do
      locals = {
        :element => yield,
        :label   => label(field, options[:label])
      }
      if has_errors_on?(field)
        locals.merge!(:error => error_message(field, options))
        @template.render :partial => 'forms/field_with_errors',
                         :locals  => locals
      else
        @template.render :partial => 'forms/field',
                         :locals  => locals
      end
    end
  end
  
  def error_message(field, options)
    if has_errors_on?(field)
      errors = object.errors.on(field)
      errors.is_a?(Array) ? errors.to_sentence : errors
    else
      ''
    end
  end
  
  def has_errors_on?(field)
    !(object.nil? || object.errors.on(field).blank?)
  end
end
