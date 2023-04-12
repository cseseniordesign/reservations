require 'models/user'
require 'models/vehicle'
require 'models/resource'
require 'models/permission'
require 'models/emergency_contact'
require 'csv'
require 'date'

USER_STATII = [
    'None',
    'NU Student (UNL, UNO, UNMC, UNK)',
    'NU Faculty (UNL, UNO, UNMC, UNK)',
    'NU Staff (UNL, UNO, UNMC, UNK)',
    'NU Alumni (UNL, UNO, UNMC, UNK)',
    'Non-NU Student (All Other Institutions)',
    'NIS/NIC Partner (NIS/NIC Affiliated Business Employee, Military Veterans)',
    'Community'
]

EXPIRATION_DATE_SEARCH_OPERATIONS = [
    '<',
    '&le;',
    '>',
    '&ge;',
    '='
]

before '/admin/users*' do
    unless has_permission?(Permission::MANAGE_USERS) || has_permission?(Permission::SUPER_USER)
        raise Sinatra::NotFound
    end
end

get '/admin/users/download/?' do
    # load up a CSV with the data
    users = User.where(:service_space_id => SS_ID)
    csv_string = CSV.generate do |csv|
        csv << ["User ID", "Username", "Email", "First Name", "Last Name", "University Status", "Date Created", "Space Status", "Expiration Date"]
        users.each do |user|
            csv << [user.id, user.username, user.email, user.first_name, user.last_name, user.university_status, (user.date_created.strftime('%Y-%m-%d') rescue ''), user.space_status, (user.expiration_date.strftime('%Y-%m-%d') rescue '')]
        end
    end

    content_type 'application/csv'
    attachment 'users.csv'
    csv_string
end

get '/admin/users/vehicle/download/?' do
# load up a CSV with the data
    todays_date = Date.today.strftime("%Y-%m-%d")
    users = User.where(:service_space_id => SS_ID)
    vehicles = Vehicle.joins("INNER JOIN users ON users.id = vehicles.user_id AND users.expiration_date IS NOT NULL AND STR_TO_DATE(users.expiration_date, '%Y-%m-%d') >= #{ todays_date}").all
    csv_string = CSV.generate do |csv|
        csv << ["First Name", "Last Name", "License Plate", "State", "Make", "Model"]
        if !vehicles.nil?
            vehicles.each do |vehicle|
                users.each do |user|
                    if vehicle.user_id == user.id
                        csv << [user.first_name, user.last_name, vehicle.license_plate, vehicle.state, vehicle.make, vehicle.model]
                    end
                end
            end
        end
    end

    content_type 'application/csv'
    attachment 'vehicles.csv'
    csv_string
end

get '/admin/users/?' do
    @breadcrumbs << {:text => 'Admin Users'}

    first_name = params[:first_name]
    last_name = params[:last_name]
    email = params[:email]
    studio_status = params[:studio_status]
    expiration_date = params[:expiration_date]
    expiration_date_operation = params[:expiration_date_operation]
    sort_by_name = params[:sort_by_name]
    sort_by_email = params[:sort_by_email]
    sort_by_expiration = params[:sort_by_expiration]

    # get all the users unless the page has initially loaded (params = 0)
    users = []
    if params.length > 0
        users = User.includes(:resource_authorizations => :resource).where(:service_space_id => SS_ID)
    end
    
    unless first_name.nil? || first_name.length == 0
        users = users.where("first_name LIKE ?", "%#{first_name}%")
    end

    unless last_name.nil? || last_name.length == 0
        users = users.where("last_name LIKE ?", "%#{last_name}%")
    end

    unless email.nil? || email.length == 0
        users = users.where("email LIKE ?", "%#{email}%")
    end

    unless studio_status.nil? || studio_status.length == 0
        users = users.where(:university_status => studio_status)
    end

    unless expiration_date.nil? || expiration_date.length == 0 || expiration_date_operation.nil? || expiration_date_operation.to_i < 1
        # need to convert the date string so it is in a format the database can easily understand
        converted_date = Date.strptime(expiration_date, "%m/%d/%Y").strftime("%Y-%m-%d")
        case expiration_date_operation.to_i
        when 1
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') < ?", converted_date)
        when 2
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') <= ?", converted_date)
        when 3
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') > ?", converted_date)
        when 4
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') >= ?", converted_date)
        else
            users = users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') = ?", converted_date)
        end
    end

    # sort the users
    if users.length > 0
        if sort_by_email == "desc"
            users = users.order(email: :desc).all.to_a
        elsif sort_by_email == "asc"
            users = users.order(email: :asc).all.to_a
        elsif sort_by_expiration == "desc"
            users = users.order(expiration_date: :desc).all.to_a
        elsif sort_by_expiration == "asc"
            users = users.order(expiration_date: :asc).all.to_a
        elsif sort_by_name == "desc"
            users = users.order(:last_name, :first_name).all.to_a.reverse
        elsif sort_by_name == "asc"
            users = users.order(:last_name, :first_name).all.to_a
        else
            # default:
            users = users.order(:last_name, :first_name).all.to_a
        end
    end

    erb :'admin/users', :layout => :fixed, :locals => {
        :users => users,
        :first_name => first_name,
        :last_name => last_name,
        :email => email,
        :studio_status => studio_status,
        :expiration_date => expiration_date,
        :expiration_date_operation => expiration_date_operation,
        :sort_by_name => sort_by_name,
        :sort_by_email => sort_by_email,
        :sort_by_expiration => sort_by_expiration
    }
end

get '/admin/users/create/?' do
    @breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Create User'}
    erb :'admin/new_user', :layout => :fixed, :locals => {
        :user => User.new
    }
end

post '/admin/users/:user_id/renew/?' do
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:permissions).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found"
        redirect '/admin/users/'
    end

    user.set_expiration_date(Date.today + 30)

    status = "expired"
    if user.is_current?
        status = "current"
    end
    
    if user.space_status.include?("_no_email")
        status = status + "_no_email"
    end
    
    user.space_status = status
    user.save

    flash :success, 'User Membership Renewed', 'Your user has been renewed.'
    redirect '/admin/users/'
end

get '/admin/users/:user_id/edit/?' do
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:permissions).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found"
        redirect '/admin/users/'
    end

    primary_emergency_contact = EmergencyContact.new
    if user.primary_emergency_contact_id.present?
        primary_emergency_contact = EmergencyContact.find_by(:id => user.primary_emergency_contact_id)
    end

    secondary_emergency_contact = EmergencyContact.new
    if user.secondary_emergency_contact_id.present?
        secondary_emergency_contact = EmergencyContact.find_by(:id => user.secondary_emergency_contact_id)
    end

    @breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Edit User'}
    erb :'admin/edit_user', :layout => :fixed, :locals => {
        :user => user,
        :vehicles => Vehicle.where(:user_id => user.id).all,
        :permissions => Permission.where.not(:id => Permission::SUPER_USER).all,
        :su_permission => Permission.find(Permission::SUPER_USER),
        :primary_emergency_contact => primary_emergency_contact,
        :secondary_emergency_contact => secondary_emergency_contact
    }
end

post '/admin/users/:user_id/edit/?' do
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:permissions).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found"
        redirect '/admin/users/'
    end

    # check that username is not taken
    name_user = User.find_by(:username => params[:username])
    unless name_user.nil? || name_user == user
        flash(:alert, 'Username Taken', 'Sorry, another user has already taken that username.')
        redirect back
    end

    # save everything except status first so that an accurate expiration date is used when building the status
    user.update({
        :first_name => params[:first_name],
        :last_name => params[:last_name],
        :email => params[:email],
        :username => params[:username],
        :university_status => params[:university_status]
    })

    if params[:expiration_date].nil? || params[:expiration_date].empty?
        user.set_expiration_date(nil)
    else
        user.set_expiration_date(calculate_time(params[:expiration_date], 0, 0, 'am'))
    end

    # figure out if space_status should be expired or current
    status = "expired"
    if user.is_current?
        status = "current"
    end

    # if user wants to opt out then add no_email to space_status
    if params[:email_preference] == "no_email"
        status = status + "_no_email"
    end

    user.space_status = status
    user.save

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
    secondary_contact_provided = secondary_contact_name.present? && secondary_contact_relationship.present? && secondary_contact_phone1.present?

    if primary_contact_provided
        begin
            primary_emergency_contact = EmergencyContact.new
            # check if the user already has a primary emergency contact so we can edit it instead of creating a new one
            if user.primary_emergency_contact_id.present?
                primary_emergency_contact = EmergencyContact.find_by(:id => user.primary_emergency_contact_id)
                if primary_emergency_contact.nil?
                    # the primary_emergency_contact_id saved to the user doesn't exist so we will just save a new one
                    primary_emergency_contact = EmergencyContact.new
                end
            end
            primary_emergency_contact.name = primary_contact_name
            primary_emergency_contact.relationship = primary_contact_relationship
            primary_emergency_contact.primary_phone_number = primary_contact_phone1
            primary_emergency_contact.secondary_phone_number = primary_contact_phone2
            primary_emergency_contact.save
            user.primary_emergency_contact_id = primary_emergency_contact.id
            user.save
        rescue => exception
            flash(:error, 'Primary Emergency Contact Save Failed', exception.message)
            redirect back
        end
    end

    if secondary_contact_provided
        begin
            secondary_emergency_contact = EmergencyContact.new
            # check if the user already has a primary emergency contact so we can edit it instead of creating a new one
            if user.secondary_emergency_contact_id.present?
                secondary_emergency_contact = EmergencyContact.find_by(:id => user.secondary_emergency_contact_id)
                if secondary_emergency_contact.nil?
                    # the secondary_emergency_contact_id saved to the user doesn't exist so we will just save a new one
                    secondary_emergency_contact = EmergencyContact.new
                end
            end
            secondary_emergency_contact.name = secondary_contact_name
            secondary_emergency_contact.relationship = secondary_contact_relationship
            secondary_emergency_contact.primary_phone_number = secondary_contact_phone1
            secondary_emergency_contact.secondary_phone_number = secondary_contact_phone2
            secondary_emergency_contact.save
            user.secondary_emergency_contact_id = secondary_emergency_contact.id
            user.save
        rescue => exception
            flash(:error, 'Secondary Emergency Contact Save Failed', exception.message)
            redirect back
        end
    end

    # check the permissions, check for new ones
    params.select {|k,v| k =~ /permission_*/}.each do |k,v|
        if params.checked?(k)
            perm_id = k.split('permission_')[1].to_i
            unless user.has_permission?(perm_id)
                user.permissions << Permission.find(perm_id)
            end
        end
    end

    # check for any removed
    user.permissions.each do |perm|
        unless params.checked?("permission_#{perm.id}")
            user.permissions.delete(perm)
        end
    end

    if params.checked?('make_trainer')
        user.make_trainer_status
    else
        user.remove_trainer_status
    end

    flash :success, 'User Updated', 'Your user has been updated.'
    redirect '/admin/users/'

end

post '/admin/users/:user_id/delete/?' do
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found."
        redirect '/admin/users/'
    end

    user.destroy

    flash :success, 'User Deleted', 'That user has been deleted.'
    redirect '/admin/users/'
end

post '/admin/users/create/?' do
    # check that username is not taken
    unless User.find_by(:username => params[:username]).nil?
        flash(:alert, 'Username Taken', 'Sorry, another user has already taken that username.')
        redirect back
    end

    # check password is at least 8 characters
    unless params[:password].length >= 8
        flash(:alert, 'Password too short', 'Sorry, your password must be at least 8 characters.')
        redirect back
    end

    # check that password matches confirmation
    unless params[:password] == params[:password2]
        flash(:alert, 'Passwords do not match', 'Sorry, your passwords do not match.')
        redirect back
    end

    params.delete('password2')
    params[:expiration_date] = params[:expiration_date].nil? || params[:expiration_date].empty? ? nil : calculate_time(params[:expiration_date], 0, 0, 'am')
    user = User.new(params)
    user.created_by_user_id = @user.id
    user.space_status = 'current'
    user.service_space_id = SS_ID
    user.save

    user.set_image_data(params)
    if params[:expiration_date].nil? || params[:expiration_date].empty?
        user.set_expiration_date(nil)
    else
        user.set_expiration_date(calculate_time(params[:expiration_date], 0, 0, 'am'))
    end

    flash :success, 'User Created', 'Your user has been created.'
    redirect '/admin/users/'
end

get '/admin/users/:user_id/manage/?' do
    @breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Manage User Permissions'}
    # check that the admin user has permission to manage this user
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:resource_authorizations).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found."
        redirect '/admin/users/'
    end

    # Get user tool options
    tools = Resource.where(:service_space_id => SS_ID).order(:name).all.to_a
    tools.sort_by! {|tool| tool.category_name.downcase + tool.name.downcase + tool.model.downcase}

    erb :'admin/manage_authorizations', :layout => :fixed, :locals => {
        :user => user,
        :tools => tools
    }
end

get '/admin/users/modify_expirations/?' do
    @breadcrumbs << {:text => 'Admin Users', :href => '/admin/users/'} << {:text => 'Modify Expirations'}
    erb :'admin/modify_expirations', :layout => :fixed
end

post '/admin/users/modify_expirations/?' do
    days_to_add = params[:days_to_add]
    todays_date = Date.today.strftime("%Y-%m-%d")
    users = User.where("expiration_date IS NOT NULL AND STR_TO_DATE(expiration_date, '%Y-%m-%d') >= ?", todays_date).all
    users_updated = users.length
    for user in users do
        user.expiration_date = user.expiration_date + days_to_add.to_i.day
        user.save
    end
    plural = days_to_add == 1 ? "" : "s"
    flash :success, "Save successful", "#{days_to_add} day#{plural} added to the expiration date#{plural} of #{users_updated} user#{plural}."
    redirect '/admin/users/'
end

post '/admin/users/:user_id/manage/?' do
    # check that the admin user has permission to manage this user
    if params[:user_id].to_i == @user.id
        user = @user
    else
        user = User.includes(:resource_authorizations).where(:id => params[:user_id], :service_space_id => SS_ID).first
    end

    if user.nil?
        flash :alert, "Not Found", "Sorry, that user was not found."
        redirect '/admin/users/'
    end

    # check for removed permissions
    user.authorized_resource_ids.each do |resource_id|
        unless params.has_key?("permission_#{resource_id}") && params["permission_#{resource_id}"] == 'on'
            ResourceAuthorization.find_by(:user_id => user.id, :resource_id => resource_id).delete
        end
    end

    # now add new permissions that are checked
    params.each do |key, value|
        if key.start_with?('permission_') && value == 'on'
            id = key.split('permission_')[1].to_i
            # check if the user already has permission for this tool
            unless user.authorized_resource_ids.include?(id)
                ResourceAuthorization.create(
                    :user_id => user.id,
                    :resource_id => id,
                    :authorized_date => Time.now
                )
            end
        end
    end

    flash :success, 'User Authorizations Updated', "User #{user.username}'s authorizations have been updated."
    redirect '/admin/users/'
end