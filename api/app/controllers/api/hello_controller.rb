class Api::HelloController < ApplicationController

  # GET /api/hello?name=Tom
  def index
    name = hello_params[:name] || 'World'
    render json: {
      message: "Hello #{name}",
      method: "GET"
    }
  end

  # POST /api/hello
  def create
    name = hello_params[:name] || 'World'
    render json: {
      message: "Hello #{name}",
      method: "POST"
    }
  end

  def hello_params
    params.permit(:name)
  end
end
