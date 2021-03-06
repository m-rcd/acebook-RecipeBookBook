# frozen_string_literal: true

require 'rails_helper'
require 'helpers/post_helper_spec.rb'

RSpec.describe Api::V1::PostsController, type: :controller do
  before(:each) do
    @user = build(:user)
    @user.confirm
    sign_in @user
    @user_2 = build(:user_2)
    @user_2.confirm
  end

  describe 'CREATE Post' do
    context 'successful creation' do
      it 'responds with 201' do
        create_post('Hello, world!')
        expect(response).to have_http_status(201)
      end

      it 'creates a post' do
        create_post('Hello, world!')
        expect(Post.find_by(message: 'Hello, world!')).to be
      end

      it 'should return new post as JSON' do
        create_post('Hello, JSON!')
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(1)
        expect(json["message"]).to eq('Hello, JSON!')
        expect(json["user_id"]).to eq(1)
      end
    end

    context 'unsuccessful creation ' do
      it 'responds with 422 when given empty message' do
        create_post('')
        expect(response).to have_http_status(422)
      end

      it "should return error message 'can't be blank'" do
        create_post('')
        json = JSON.parse(response.body)
        expect(json["message"]).to include("can't be blank")
      end
    end
  end

  describe 'GET INDEX' do
    it 'responds with 200' do
      get :index
      expect(response).to have_http_status(200)
    end

    it 'returns json with posts data' do
      create_post('Hello, World!')
      get :index
      json = JSON.parse(response.body)[0]
      expect(json["id"]).to eq(1)
      expect(json["message"]).to eq('Hello, World!')
      expect(json["user_id"]).to eq(1)
    end
  end

  describe 'GET SHOW' do
    it 'responds with 200' do
      create_post('Hello, World!')
      get :show, params: { id: 1 }
      expect(response).to have_http_status(200)
    end

    it 'returns json with post data' do
      create_post('Hello, World!')
      get :show, params: { id: 1 }
      json = JSON.parse(response.body)
      expect(json["id"]).to eq(1)
      expect(json["message"]).to eq('Hello, World!')
      expect(json["user_id"]).to eq(1)
    end
  end

  describe 'UPDATE Posts' do
    context 'within 10 minutes of creation' do
      it 'can edit own post' do
        create_post('Hello, world!')
        new_post = Post.find_by(message: 'Hello, world!')
        new_post_id = new_post.id
        new_message = 'Hello, Aliens!'
        patch :update, params: { post: { message: new_message }, id: new_post_id }
        updated_post = Post.find_by(message: new_message)
        expect(updated_post.message).to eq(new_message)
        expect(updated_post.id).to eq(new_post_id)
      end

      xit "cannot edit another user's post" do
        create_post('Hello, world!')
        new_post = Post.find_by(message: 'Hello, world!')
        new_post_id = new_post.id
        sign_out @user
        sign_in @user_2
        patch :update,
              params: { post: { message: 'Hello, Aliens!' }, id: new_post_id }
        expect(response.body).to eq("Cannot edit another user's post")
      end

      it 'responds with 422 trying to update a non-existant post' do
        patch :update,
              params: { post: { message: 'Hello, Aliens!' }, id: 9_999_999 }
        expect(response).to have_http_status(422)
      end

      # it 'responds with 422 failing to update a post in the database' do
      #   create_post('Hello, world!')
      #   new_post = Post.find_by(message: 'Hello, world!')
      #   new_post_id = new_post.id
      #   new_message = 'Hello, Aliens!'
      #   allow(Post).to receive(:update).and_return(false)
      #   patch :update, params: { post: { message: new_message }, id: new_post_id }
      #   expect(response).to have_http_status(422)
      # end
    end

    context 'after 10 minutes from creation' do
      xit 'cannot edit a post' do
        @future_time = Time.now + 601
        create_post('Hello, world!')
        allow(Time).to receive(:now).and_return(@future_time)
        new_post = Post.find_by(message: 'Hello, world!')
        get :edit, params: { post: { message: new_post.message}, id: new_post.id }
        expect(response).to redirect_to(posts_url)
      end
    end
  end

  describe 'DELETE Posts' do
    context 'successful delete' do
      it 'responds with 204' do
        create_post('Post by user 1 to be deleted')
        new_post = Post.find_by(message: 'Post by user 1 to be deleted')
        new_post_id = new_post.id
        delete :destroy, params: { id: new_post_id }
        expect(response).to have_http_status(204)
      end

      it 'should delete own post' do
        create_post('Post by user 1 to be deleted')
        new_post = Post.find_by(message: 'Post by user 1 to be deleted')
        new_post_id = new_post.id
        delete :destroy, params: { id: new_post_id }
        expect(Post.find_by(id: new_post_id)).to be_nil
      end
    end

    context 'unsuccessful delete' do
      it 'responds with 422 trying to delete a non-existant post' do
        delete :destroy, params: { id: 999 }
        expect(response).to have_http_status(422)
      end

      xit 'line 59 of PostsController#destroy cannot be tested atm' do
        render json: @post.errors, status: :unprocessable_entity 
        "also need to test this whole method further"
      end


      xit "should not delete another user's post" do
        create_post('Post by user 1 to be deleted')
        new_post = Post.find_by(message: 'Post by user 1 to be deleted')
        new_post_id = new_post.id
        sign_out @user
        sign_in @user_2
        delete :destroy, params: { id: new_post_id }
        p response.body
        json = response.body
        expect(json).to eq("Cannot delete another user's post")
      end
    end
  end
end
