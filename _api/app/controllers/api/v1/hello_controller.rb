class Api::V1::HelloController < ApplicationController
  # GET /api/v1/hello?name=Tom
  def index
    name = hello_params[:name] || "World"
    render json: {
      message: "Hello #{name}",
      method: "GET"
    }
  end

  # POST /api/v1/hello
  def create
    name = hello_params[:name] || "World"
    render json: {
      message: "Hello #{name}",
      method: "POST"
    }
  end

  private

  def hello_params
    params.permit(:name)
  end
end
