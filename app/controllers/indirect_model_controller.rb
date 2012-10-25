class IndirectModelController < AbstractController::Base
  include AbstractController::Rendering
  include AbstractController::Layouts
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  #include ActionController::UrlWriter
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers

  # Uncomment if you want to use helpers 
  # defined in ApplicationHelper in your views
  helper ApplicationHelper

  # Make sure your controller can find views
  self.view_paths = "app/views"

  # You can define custom helper methods to be used in views here
  # helper_method :current_admin
  # def current_admin; nil; end

  def show
    #render template: "hello_world/show"
    render template: "layouts/_commoncorelogo"
  end

  def build(mclass)
    case mclass.to_s
    when 'createfile'
      render template: "layouts/feedpieces/_createfileheader"
    when 'createcontent'
      render template: "layouts/feedpieces/_feedcontent"
    when 'update' 
      render template: "layouts/feedpieces/_update"
    when 'forkitem' 
      render template: "layouts/feedpieces/_forkitemheader"
    when 'favorite'
      render template: "layouts/feedpieces/_favoriteheader"
    when 'setpub'
      render template: "layouts/feedpieces/_setpubheader"
    when 'sub'
      render template: "layouts/feedpieces/_subheader"
    else
      raise 'Invalid class in IndirectModelController!'
    end
  end

  def render_partial(params)

    debugger

    if true
      return
    end

  end

end