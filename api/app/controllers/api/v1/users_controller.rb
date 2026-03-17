class Api::V1::UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /api/v1/me
  def me
    render json: current_user
  end

  def index
    users = User.all
    render json: users
  end

  def show
    user = User.find(params[:id])
    Rails.logger.warn("[LOGIN] show ** user #{user.inspect}")
    render json: user
  end

  def create
    user = User.new(user_params)
    if user.save
      render json: user, status: :created
    else
      render json: { errors: user.errors }, status: :unprocessable_entity
    end
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: user
    else
      render json: { errors: user.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    user.destroy
    head :no_content
  end

  private

  def user_params
    params.require(:user).permit(:email, :role, :status)
  end
end
