# frozen_string_literal: true
# usual order of actions is:
# index, show, new, edit, create, update and destroy

module Api::V1
  # Posts Controller
  class PostsController < ApplicationController
    def index
      @posts = Post.all.order('created_at DESC')
      render json: @posts.as_json(
        include: {
          user: { only: :email },
          comments: {
            include: {
              user: { only: :email }
            }
          }
        }
      )
    end

    def show
      @post = Post.find(params[:id])
      render json: @post
    end

    def edit
      @post = Post.find(params[:id])
      if !post_created_within_ten_minutes?
        redirect_to posts_url, alert: 'Sorry! Too late to edit, be snappier next time'
      else
        @post
      end
    end

    def create
      @post = Post.new(post_params.merge(user_id: current_user.id))
      if @post.save
        render json: @post, status: :created
      else
        render json: @post.errors, status: :unprocessable_entity
      end
    end

    def update
      @post = Post.find(params[:id])
      raise "Cannot edit another user's post" unless
        post_created_by_current_user?
      @post.update(post_params) ? (redirect_to @post) : (render 'edit')
    end

    def destroy
      begin 
        @post = Post.find(params[:id])

        if post_created_by_current_user? 
          if @post.destroy 
            head :no_content, status: :ok
          else 
            render json: @post.errors, status: :unprocessable_entity 
          end
        else 
          render json: "Cannot delete another user's post", status: :unprocessable_entity
        end 
      rescue ActiveRecord::RecordNotFound
        render json: "Record not found", status: :unprocessable_entity
      end


#         raise("Cannot delete another user's post") unless
# post_created_by_current_user?
      # raise("Cannot delete another user's post") unless
      #   post_created_by_current_user?
    end

    private

    def post_params
      params.require(:post).permit(:message, :user_id)
    end

    # def can_edit_post?
    #   post_created_by_current_user? && post_created_within_ten_minutes?
    # end

    def post_created_by_current_user?
      @post.user_id === current_user.id
    end

    def post_created_within_ten_minutes?
      Time.current - @post.created_at <= 600
    end
  end
end