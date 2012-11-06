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

      #debugger

      @mult = obj.multiplicity?
      @howmany = obj.objnum
      @who = Teacher.find(obj.whoid)
      @wholink = "/#{@who.username}"
      @when = time_ago_in_words(Time.at(obj.timestamp).to_datetime)

      case obj.wclass
      when 'createcontent'

        @what = Binder.find(obj.whatid)
        if @what.parents.size==2
          @where = Binder.find(@what.parent['id'])
          @wherelink = named_binder_route(@where)
        else
          @where = Binder.find(@what.parents[1]['id'])
          @wherelink = named_binder_route(@where)
        end

        render template: "layouts/feedpieces/wrappers/_createcontent"
      when 'createfile'

        @what = Binder.find(obj.whatid)
        if @what.parents.size==2
          @where = Binder.find(@what.parent['id'])
          @wherelink = named_binder_route(@where)
        else
          @where = Binder.find(@what.parents[1]['id'])
          @wherelink = named_binder_route(@where)
        end 

        render template: "layouts/feedpieces/wrappers/_createfile"
      when 'update' 

        @what = Binder.find(Feedobject.find(obj.feedobjectids.first).binderid)
        @whatlink = named_binder_route(@what)
        if @howmany>1
          @what2 = Binder.find(Feedobject.find(obj.feedobjectids.second).binderid)
          @whatlink2 = named_binder_route(@what2)
          if @howmany>2
            @what3 = Binder.find(Feedobject.find(obj.feedobjectids.third).binderid)
            @whatlink3 = named_binder_route(@what2)
          end
        end

        render template: "layouts/feedpieces/wrappers/_update"
      when 'forkitem' 

        @what = Binder.find(obj.whatid)
        @whatlink = named_binder_route(@what)
        if !@mult
          @whoelse = Teacher.where(:username => Log.find(Feedobject.find(obj.feedobjectids.first).logid).params['username'].to_s).first
          @whoelselink = "/#{@whoelse.username}"
        end

        render template: "layouts/feedpieces/wrappers/_forkitem"
      # when 'favorite'

      #   @what = Binder.find(self.whatid)
      #   @where = 

      #   render template: "layouts/feedpieces/wrappers/_favorite"
      when 'setpub'

        # requires nothing additional

        render template: "layouts/feedpieces/wrappers/_setpub"
      when 'sub'

        @what = Teacher.find(self.whatid)

        render template: "layouts/feedpieces/wrappers/_sub"
      else
        raise "Invalid wrapper class #{obj.oclass}"
      end
    end
  end

  def expire_fragment(id)

    #debugger

    expire_fragment(id)

  end

  def render_partial(params)

    #debugger

    if true
      return
    end

  end

end