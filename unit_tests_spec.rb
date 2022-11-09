require_relative './utils/spec_helper'

describe "Test Login Page" do
  def app
    Sinatra::Application
  end

  it "login page loads" do
    get '/login/?'
    expect(last_response).to be_ok
  end

  it "successful login with valid credentials" do
    post '/login/?', params={:username => "development2", :password => "Welcome123"}
    follow_redirect!
    expect(last_response).to be_ok
    expect(last_response.body).to include('Welcome to Innovation Studio Manager')
  end

  it "unsuccessful login with invalid credentials" do
    post '/login/?', params={:username => "development23", :password => "Welcome123"}
    follow_redirect!
    expect(last_response).to be_ok
    expect(last_response.body).to include('Username/password combination is incorrect.')
  end
end

describe "Test New Member Sign-Up" do
  def app
    Sinatra::Application
  end

  it "new member page loads" do
    get '/new_members/'
    expect(last_response).to be_ok
  end
end