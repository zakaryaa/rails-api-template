# frozen_string_literal: true

class Api::V1::User::SessionsController < Devise::SessionsController
  respond_to :json
  before_action :configure_permitted_parameters, only: :update

  def create
    resource = User.find_for_database_authentication(:email=>params[:user][:email])
    return invalid_login_attempt unless resource

    if resource.valid_password?(params[:user][:password])
      sign_in("user", resource)
      render :json=> {:success=>true, :access_token=>current_token, :expires_in => resource.expires_in, :email=>resource.email}
      return
    end
    invalid_login_attempt
  end

  def destroy
    sign_out(resource_name)
  end

  private

  def current_token
    request.env['warden-jwt_auth.token']
  end

  def respond_with(resource, _opts = {})
    render json: resource
  end

  def respond_to_on_destroy
    head :no_content
  end

  def ensure_params_exist
    return unless params[:user_login].blank?
    render :json=>{:success=>false, :message=>"missing user_login parameter"}, :status=>422
  end

  def invalid_login_attempt
    warden.custom_failure!
    render :json=> {:success=>false, :message=>"Error with your login or password"}, :status=>401
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:update, keys: [:email])
  end

end