class IndirectModelController < AbstractController::Base

  require 'action_view'

  include AbstractController::Rendering
  include AbstractController::Layouts
  include AbstractController::Helpers
  include AbstractController::Translation
  include AbstractController::AssetPaths
  #include ActionController::UrlWriter
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers

  include ActionView::Helpers::DateHelper

  # Uncomment if you want to use helpers 
  # defined in ApplicationHelper in your views
  helper ApplicationHelper
  helper BinderHelper
  helper TeacherHelper
#  helper Helpers::DateHelper

  # Make sure your controller can find views
  self.view_paths = "app/views"

  # You can define custom helper methods to be used in views here
  # helper_method :current_admin
  # def current_admin; nil; end

  def show
    #render template: "hello_world/show"
    render template: "layouts/_commoncorelogo"
  end

  def pseudorender(obj)

    #debugger

    if obj.class == Feedobject
      case obj.oclass
      when 'binders'
        @binder = Binder.find(obj.binderid)
        render template: "layouts/feedpieces/objects/_binder"
      when 'teachers'
        @teacher = Teacher.find(obj.teacherid)
        render template: "layouts/feedpieces/objects/_teacher"
      else
        raise "Invalid feedobject class #{obj.oclass}"
      end
      # when 'createfile'
      #   render template: "layouts/feedpieces/_createfileheader"
      # when 'update' 
      #   render template: "layouts/feedpieces/_update"
      # when 'forkitem' 
      #   render template: "layouts/feedpieces/_forkitemheader"
      # when 'favorite'
      #   render template: "layouts/feedpieces/_favoriteheader"
      # when 'setpub'
      #   render template: "layouts/feedpieces/_setpubheader"
      # when 'sub'
      #   render template: "layouts/feedpieces/_subheader"
      # else
      #   raise 'Invalid feedobject class!'
      # end
    elsif obj.class == Wrapper

      @mult = obj.multiplicity?
      @time = time_ago_in_words(Time.at(obj.timestamp).to_datetime)



      #if obj.

      case obj.wclass
      when 'createfile'



        render template: "layouts/feedpieces/wrappers/_createfile"
      when 'update' 

        render template: "layouts/feedpieces/wrappers/_update"
      when 'forkitem' 

        render template: "layouts/feedpieces/wrappers/_forkitem"
      when 'favorite'

        render template: "layouts/feedpieces/wrappers/_favorite"
      when 'setpub'

        render template: "layouts/feedpieces/wrappers/_setpub"
      when 'sub'

        render template: "layouts/feedpieces/wrappers/_sub"
      else
        raise "Invalid wrapper class #{obj.oclass}"
      end
    end
  end

  def render_partial(params)

    debugger

    if true
      return
    end

  end

end