class InferencingHelpersController < ActionController::Base
  self.template_root = "#{File.dirname(__FILE__)}/../fixtures/"

  def self.controller_path; 'inferencing_helpers' end

  def show_specified_positional_path
    render :inline => "<%= flange_path('a_widget', 'a_flange') %>"
  end

  def show_inferred_positional_path
    @widget = 'a_widget'
    render :inline => "<%= flange_path('a_flange') %>"
  end

  def show_instance_id_inference
    @widget_id = 'a_widget'
    render :inline => "<%= flange_path('a_flange') %>"
  end

  def show_inference_precedence
    @widget_id = 'bogus_widget'
    @widget = 'a_widget'
    render :inline => "<%= flange_path('a_flange') %>"
  end

  def show_deep_inferred_positional_path
    @widget = 'a_widget'
    render :inline => "<%= grommet_path('a_flange','a_grommet') %>"
  end

  def show_positionals_always_overrides_instance_variables
    @widget = 'bogus_widget'
    @flange = 'bogus_flange'
    render :inline => "<%= grommet_path('a_widget', 'a_flange', 'a_grommet') %>"
  end

  def show_options_always_overrides_instance_variables
    @widget = 'bogus_widget'
    @flange = 'bogus_flange'
    render :inline => "<%= grommet_path('a_grommet', :widget_id => 'a_widget', :flange_id => 'a_flange') %>"
  end

  def show_positionals_always_overrides_options
    render :inline => "<%= grommet_path('a_widget', 'a_flange', 'a_grommet', :widget_id => 'bogus_widget', :flange_id => 'bogus_flange') %>"
  end

  def show_collection_helpers_need_no_arguments
    @widget = 'a_widget'
    @flange = 'a_flange'
    render :inline => "<%= grommets_path() %>"
  end

  def show_explosion_because_terminating_member_is_never_inferred
    @widget = 'a_widget'
    @flange = 'a_flange'
    @grommet = @id = @grommet_id = 'a_grommet'
    render :inline => "<%= grommet_path() %>"
  end

  def show_explosion_on_too_many_positionals
    render :inline => "<%= grommet_path('a_widget', 'a_flange', 'a_grommet', 'extra_positional') %>"
  end

  def rescue_action(e) raise e end
end
