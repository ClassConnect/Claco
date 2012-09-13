class RegistrationsController < Devise::RegistrationsController
  prepend_before_filter :require_no_authentication, :only => [ :new, :create, :cancel ]
  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy]

  # GET /resource/sign_up
  def new
    @title = "Join the beta"

<<<<<<< HEAD
    Mongo.log(  current_teacher.id.to_s,
          __method__.to_s,
          params[:controller].to_s,
          nil,
          params)

    if params[:key].nil? || params[:key].empty?
=======
    if params[:key].nil? || params[:key].empty? || Ns.where(:code => params[:key]).first.nil?
>>>>>>> 87c12a83207a4f5c920dab806dea1c5a3fe5ed1b
      redirect_to root_path
    else
      if Ns.where(:code => params[:key]).first.active
        resource = build_resource({})
        resource.code = params[:key]
        i = Invitation.where(:code => params[:key]).first
        unless i.nil?
          i.status["clicked"] = true
          i.save
        end
        respond_with resource
      else
        redirect_to root_path
      end
    end
  end

  # POST /resource
  def create
    build_resource

    Mongo.log(  current_teacher.id.to_s,
          __method__.to_s,
          params[:controller].to_s,
          nil,
          params)

    resource.code = params[:teacher][:code]
    resource.registered_at = Time.now.to_i
    resource.registered_ip = request.ip
    
    if Ns.where(:code => params[:teacher][:code]).first.active && resource.save

      Ns.where(:code => params[:teacher][:code]).first.use
      i = Invitation.where(:code => params[:teacher][:code]).first
      unless i.nil?
        i.status["signed_up"] = true
        i.save
      end

      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      if Ns.where(:code => params[:teacher][:code]).first.active
        @title = "Join the beta"
        resource.code = params[:teacher][:code]
        clean_up_passwords resource
        respond_with resource
      else
        cancel
      end
    end
  end

  # GET /resource/edit
  def edit
    render :edit

    Mongo.log(  current_teacher.id.to_s,
          __method__.to_s,
          params[:controller].to_s,
          nil,
          params)

  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    Mongo.log(  current_teacher.id.to_s,
          __method__.to_s,
          params[:controller].to_s,
          nil,
          params)

    if resource.update_with_password(resource_params)
      if is_navigational_format?
        if resource.respond_to?(:pending_reconfirmation?) && resource.pending_reconfirmation?
          flash_key = :update_needs_confirmation
        end
        set_flash_message :notice, flash_key || :updated
      end
      sign_in resource_name, resource, :bypass => true
      respond_with resource, :location => after_update_path_for(resource)
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  # DELETE /resource
  def destroy

    Mongo.log(  current_teacher.id.to_s,
          __method__.to_s,
          params[:controller].to_s,
          nil,
          params)

    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_navigational_format?
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel

    Mongo.log(  current_teacher.id.to_s,
          __method__.to_s,
          params[:controller].to_s,
          nil,
          params)

    expire_session_data_after_sign_in!
    redirect_to root_path
  end

  ###############################################################################################

              #    #  ##### #     #####  ##### #####   #### 
              #    #  #     #     #    # #     #    # #    #
              #    #  #     #     #    # #     #    # # 
              ######  ####  #     #####  ####  #####   ####
              #    #  #     #     #      #     #  #        #
              #    #  #     #     #      #     #   #  #    #
              #    #  ##### ##### #      ##### #    #  ####

  ###############################################################################################

  module Mongo
    extend self

    def log(ownerid,method,model,modelid,params,data = {})

      log = Log.new(  :ownerid => ownerid.to_s,
              :timestamp => Time.now.to_f,
              :method => method.to_s,
              :model => model.to_s,
              :modelid => modelid.to_s,
              :params => params,
              :data => data,
              :actionhash => Digest::MD5.hexdigest(ownerid.to_s+method.to_s+modelid.to_s))

      log.save

      return log.id.to_s

    end
  end

  protected

  # Build a devise resource passing in the session. Useful to move
  # temporary session data to the newly created user.
  def build_resource(hash=nil)
    hash ||= resource_params || {}
    self.resource = resource_class.new_with_session(hash, session)
  end

  # The path used after sign up. You need to overwrite this method
  # in your own RegistrationsController.
  def after_sign_up_path_for(resource)
    after_sign_in_path_for(resource)
  end

  # The path used after sign up for inactive accounts. You need to overwrite
  # this method in your own RegistrationsController.
  def after_inactive_sign_up_path_for(resource)
    respond_to?(:root_path) ? root_path : "/"
  end

  # The default url to be used after updating a resource. You need to overwrite
  # this method in your own RegistrationsController.
  def after_update_path_for(resource)
    signed_in_root_path(resource)
  end

  # Authenticates the current scope and gets the current resource from the session.
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", :force => true)
    self.resource = send(:"current_#{resource_name}")
  end
end