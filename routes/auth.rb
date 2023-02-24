require 'models/user'
require 'models/vehicle'

get '/me/?' do
  require_login
  @breadcrumbs << {:text => 'My Account'}

  vehicles = Vehicle.where(:user_id => @user.id).all

  erb :me, :layout => :fixed, :locals => {
    :vehicles => vehicles
  }
end

get '/opt_out/?' do
  require_login("me")
  @breadcrumbs << {:text => 'My Account'}
  redirect "/me/"
end

post '/me/?' do
  require_login

  @user.email = params[:email]
  @user.first_name = params[:first_name]
  @user.last_name = params[:last_name]

  # figure out if space_status should be expired or current
  status = "expired"
  if !@user.get_expiration_date.nil? && @user.get_expiration_date >= Date.today
    status = "current"
  end

  # if user wants to opt out then add no_email to space_status
  if params.checked?('email_opt_out')
    status = status + "_no_email"
  end
  @user.space_status = status
  @user.save

  flash(:success, 'Account Updated', 'Your user account has been updated.')
  redirect '/me/'
end

post '/change-password/?' do
  require_login

  # check password is at least 8 characters
  unless params[:password].length >= 8
    flash(:alert, 'Password too short', 'Sorry, your password must be at least 8 characters.')
    redirect '/me/'
  end

  # check that password matches confirmation
  unless params[:password] == params[:password2]
    flash(:alert, 'Passwords do not match', 'Sorry, your passwords do not match.')
    redirect '/me/'
  end

  @user.password = params[:password]
  @user.save

  flash(:success, 'Password Changed', 'Your password has been changed.')
  redirect '/me/'
end

get '/login/?' do
    @breadcrumbs << {:text => 'Login'}
    unless @user.nil?
      redirect '/home/'
    end
    erb :login, :layout => :fixed, :locals => {
      :next_page => params[:next_page]
  }
end

post '/login/?' do
    user = User.where(:username => params[:username]).first
    next_page = params[:next_page]
    # check user existence and password correctness
    if user.nil? || user.password != params[:password]
        flash(:danger, 'Incorrect Password', 'Username/password combination is incorrect.')
        if !next_page.nil? && next_page.length > 0
          redirect "/login/?next_page=#{next_page}"
        end
        redirect '/login/'
    end

    # it is the user, hooray
    session[:user_id] = user.id
    if !next_page.nil? && next_page.length > 0
      redirect "/#{next_page}/"
    else
      redirect '/home/'
    end
end

get '/forgot_password/' do
  erb :forgot_password, :layout => :fixed
end

post '/forgot_password/' do
  user = User.find_by(:username => params[:username].trim)
  unless user.nil?
    user.send_reset_password_email
  end

  flash :success, 'Email sent', 'An email containing instructions to reset your password has been sent.'
  redirect '/login/'
end

get '/reset_password/:token/?' do
  user = User.find_by(:reset_password_token => params[:token])
  not_found if user.nil? || user.reset_password_expiry < Time.now

  @section = nil
  erb :reset_password, :layout => :fixed, :locals => {
    :token => params[:token]
  }
end

post '/reset_password/?' do
  user = User.find_by(:reset_password_token => params[:token])
  not_found if user.nil? || user.reset_password_expiry + 5.minutes < Time.now

  # check password is at least 8 characters
  unless params[:password].length >= 8
    flash(:alert, 'Password too short', 'Sorry, your password must be at least 8 characters.')
    redirect "/reset_password/#{params[:token]}"
  end

  if (params[:password] != params[:password2])
    flash :danger, 'Password mismatch', 'Your passwords do not match.'
    redirect "/reset_password/#{params[:token]}"
  end

  user.password = params[:password]
  user.reset_password_token = nil
  user.reset_password_expiry = nil
  user.save

  flash :success, 'Password Reset', 'Your password has been reset.'
  redirect '/login/'
end

get '/logout/?' do
  session.clear
  redirect '/'
end
