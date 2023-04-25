require 'models/user'
require 'models/vehicle'

get '/me/?' do
  require_login
  @breadcrumbs << {:text => 'My Account'}

  primary_emergency_contact = EmergencyContact.new
  if @user.primary_emergency_contact_id.present?
      primary_emergency_contact = EmergencyContact.find_by(:id => @user.primary_emergency_contact_id)
      if primary_emergency_contact.nil?
        # the primary_emergency_contact_id saved to the user doesn't exist so we will just save a new one
        primary_emergency_contact = EmergencyContact.new
    end
  end

  secondary_emergency_contact = EmergencyContact.new
  if @user.secondary_emergency_contact_id.present?
      secondary_emergency_contact = EmergencyContact.find_by(:id => @user.secondary_emergency_contact_id)
      if secondary_emergency_contact.nil?
          # the secondary_emergency_contact_id saved to the user doesn't exist so we will just save a new one
          secondary_emergency_contact = EmergencyContact.new
      end
  end

  erb :me, :layout => :fixed, :locals => {
    :vehicles => Vehicle.where(:user_id => @user.id).all,
    :primary_emergency_contact => primary_emergency_contact,
    :secondary_emergency_contact => secondary_emergency_contact
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
  
  if params.checked?('promotional_opt_out')
    @user.promotional_email_status = 0
  else
    @user.promotional_email_status = 1
  end
  
  @user.space_status = status
  @user.save

  # save the user's emergency contacts
  primary_contact_name = params[:primary_contact_name]
  primary_contact_relationship = params[:primary_contact_relationship]
  primary_contact_phone1 = params[:primary_contact_phone1]
  primary_contact_phone2 = params[:primary_contact_phone2]

  secondary_contact_name = params[:secondary_contact_name]
  secondary_contact_relationship = params[:secondary_contact_relationship]
  secondary_contact_phone1 = params[:secondary_contact_phone1]
  secondary_contact_phone2 = params[:secondary_contact_phone2]

  primary_contact_provided = primary_contact_name.present? && primary_contact_relationship.present? && primary_contact_phone1.present?
  primary_contact_blank = primary_contact_name.blank? && primary_contact_relationship.blank? && primary_contact_phone1.blank?

  secondary_contact_provided = secondary_contact_name.present? && secondary_contact_relationship.present? && secondary_contact_phone1.present?
  secondary_contact_blank = secondary_contact_name.blank? && secondary_contact_relationship.blank? && secondary_contact_phone1.blank?

  begin
      primary_emergency_contact = EmergencyContact.new
      has_existing_primary = false
      # check if the user already has a primary emergency contact so we can edit it instead of creating a new one
      if @user.primary_emergency_contact_id.present?
          primary_emergency_contact = EmergencyContact.find_by(:id => @user.primary_emergency_contact_id)
          has_existing_primary = primary_emergency_contact.present?
          if !has_existing_primary
              # the primary_emergency_contact_id saved to the user doesn't exist so we will just save a new one
              primary_emergency_contact = EmergencyContact.new
          end
      end
      if primary_contact_provided || (has_existing_primary && primary_contact_blank)
        primary_emergency_contact.name = primary_contact_name
        primary_emergency_contact.relationship = primary_contact_relationship
        primary_emergency_contact.primary_phone_number = primary_contact_phone1
        primary_emergency_contact.secondary_phone_number = primary_contact_phone2
        primary_emergency_contact.save
        @user.primary_emergency_contact_id = primary_emergency_contact.id
        @user.save
      end
  rescue => exception
      flash(:error, 'Primary Emergency Contact Save Failed', exception.message)
      redirect back
  end

  begin
      secondary_emergency_contact = EmergencyContact.new
      has_existing_secondary = false
      # check if the user already has a secondary emergency contact so we can edit it instead of creating a new one
      if @user.secondary_emergency_contact_id.present?
          secondary_emergency_contact = EmergencyContact.find_by(:id => @user.secondary_emergency_contact_id)
          has_existing_secondary = secondary_emergency_contact.present?
          if !has_existing_secondary
              # the secondary_emergency_contact_id saved to the user doesn't exist so we will just save a new one
              secondary_emergency_contact = EmergencyContact.new
          end
      end
      if secondary_contact_provided || (has_existing_secondary && secondary_contact_blank)
        secondary_emergency_contact.name = secondary_contact_name
        secondary_emergency_contact.relationship = secondary_contact_relationship
        secondary_emergency_contact.primary_phone_number = secondary_contact_phone1
        secondary_emergency_contact.secondary_phone_number = secondary_contact_phone2
        secondary_emergency_contact.save
        @user.secondary_emergency_contact_id = secondary_emergency_contact.id
        @user.save
      end
  rescue => exception
      flash(:error, 'Secondary Emergency Contact Save Failed', exception.message)
      redirect back
  end

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

get '/check_in_login/?' do
  unless @user.nil?
    redirect '/check_in/'
  end
  erb :check_in_login, :layout => :fixed_no_toolbar
end

post '/check_in_login/?' do
  user = User.where(:username => params[:username]).first
  # check user existence and password correctness
  if user.nil? || user.password != params[:password]
    flash(:danger, 'Incorrect Password', 'Username/password combination is incorrect.')
    redirect '/check_in_login/'
  end

  # it is the user, hooray
  session[:user_id] = user.id
  redirect '/check_in/'
end

get '/forgot_password_check_in/' do
  erb :forgot_password, :layout => :fixed_no_toolbar
end

post '/forgot_password_check_in/' do
  user = User.find_by(:username => params[:username].trim)
  unless user.nil?
    user.send_reset_password_email
  end

  flash :success, 'Email sent', 'An email containing instructions to reset your password has been sent.'
  redirect '/check_in_login/'
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
