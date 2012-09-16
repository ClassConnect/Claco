class PasswordsController < Devise::PasswordsController
	  # GET /resource/password/new
  def new
    build_resource({})
  end

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    if successfully_sent?(resource)
      respond_with({}, :location => root_path)
    else
      respond_with(resource)
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    self.resource = resource_class.new
    resource.reset_password_token = params[:reset_password_token]
  end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message(:notice, flash_message) if is_navigational_format?
      sign_in(resource_name, resource)
      respond_with resource, :location => root_path
    else
      respond_with resource
    end
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
	def after_sending_reset_password_instructions_path_for(resource_name)
		root_path
	end

end