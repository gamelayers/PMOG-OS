class OpaqueResourceNamesTestController < ActionController::Base
  self.template_root = "#{File.dirname(__FILE__)}/../fixtures/"

  def self.controller_path; 'opaque_resource_names_test' end

  def show_widget_path
    render :inline => "<%= widget_path %>"
  end

  def show_widgets_path
    render :inline => "<%= widgets_path %>"
  end

  def show_widgets_member_path
    render :inline => "<%= widget_path('a_widget') %>"
  end

  def show_flange_path
    render :inline => "<%= flange_path %>"
  end

  def show_grommet_path
    render :inline => "<%= grommet_path %>"
  end

  def show_grommets_path
    render :inline => "<%= grommets_path('a_widget', 'a_flange') %>"
  end

  def show_grommets_member_path
    render :inline => "<%= grommet_path('a_widget', 'a_flange', 'a_grommet') %>"
  end

  def rescue_action(e) raise e end
end
