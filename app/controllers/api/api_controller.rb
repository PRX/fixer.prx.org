module Api
  class ApiController < ApplicationController
    skip_before_filter :verify_authenticity_token
    skip_before_filter :authenticate
    before_action :doorkeeper_authorize!
    respond_to :json

    # Find the user that owns the access token
    def current_resource_owner
      User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
    end

    def current_application
      doorkeeper_token.application if doorkeeper_token
    end
  end
end
