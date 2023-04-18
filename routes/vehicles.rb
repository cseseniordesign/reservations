require 'models/user'
require 'models/vehicle'

get '/vehicle/add/?' do
  require_login
  @breadcrumbs << {:text => 'My Account', :href => '/me/'} << {text: 'Add Vehicle'}
  	if params[:user_id].present? && !(has_permission?(Permission::MANAGE_USERS) || has_permission?(Permission::SUPER_USER))
        raise Sinatra::NotFound
    end

  erb :new_vehicle, :layout => :fixed, :locals => {
    :vehicle => Vehicle.new,
	:user_id => params[:user_id]
  }
end

get '/vehicle/:vehicle_id/edit/?' do
    require_login
    @breadcrumbs << {:text => 'My Account', :href => '/me/'} << {text: 'Edit Vehicle'}
	if params[:user_id].present? && !(has_permission?(Permission::MANAGE_USERS) || has_permission?(Permission::SUPER_USER))
        raise Sinatra::NotFound
    end
    vehicle = Vehicle.find_by(:id => params[:vehicle_id])
	if vehicle.nil?
		# that vehicle does not exist
		flash(:danger, 'Not Found', 'That vehicle does not exist')
		if params[:user_id].present?
			redirect "/admin/users/#{params[:user_id]}/edit/"
		else
			redirect '/me/'
		end
	end
    erb :new_vehicle, :layout => :fixed, :locals => {
      :vehicle => vehicle,
	  :user_id => params[:user_id]
    }
  end

post '/vehicle/:vehicle_id/edit/?' do
	license_plate = params[:license_plate]
	state = params[:state]
	make = params[:make]
	model = params[:model]
    vehicle = Vehicle.find_by(:id => params[:vehicle_id])
	if vehicle.nil?
		# that vehicle does not exist
		flash(:danger, 'Not Found', 'That vehicle does not exist')
		if params[:user_id].present?
			redirect "/admin/users/#{params[:user_id]}/edit/"
		else
			redirect '/me/'
		end
	end

	if license_plate.blank? || state.blank? || make.blank? || model.blank?
		flash(:error, 'Vehicle Update Failed', "Please fill out all required fields.")
		redirect back
	else
		begin
			vehicle.license_plate = license_plate
            vehicle.state = state
            vehicle.make = make
            vehicle.model = model
            if params[:user_id].present?
				user = User.find_by(:id => params[:user_id])
				if user.nil?
					raise StandardError.new "A user does not exist with user ID #{params[:user_id]}"
				end
				vehicle.user_id = params[:user_id]
				if user.is_current?
					user.send_vehicle_information_update
				end
			else
				vehicle.user_id = @user.id
				if @user.is_current?
					@user.send_vehicle_information_update
				end
			end
			vehicle.save

			# notify that it worked
			flash(:success, 'Vehicle Update Successful', "Your vehicle has been updated.")
			if params[:user_id].present?
				redirect "/admin/users/#{params[:user_id]}/edit/"
			else
				redirect '/me/'
			end
		rescue => exception
			flash(:error, 'Vehicle Update Failed', exception.message)
			redirect back
		end
	end
end


post '/vehicle/add/?' do
    vehicle = Vehicle.new
	license_plate = params[:license_plate]
	state = params[:state]
	make = params[:make]
	model = params[:model]

	if license_plate.blank? || state.blank? || make.blank? || model.blank?
		flash(:error, 'Vehicle Addition Failed', "Please fill out all required fields.")
		redirect back
	else
		begin
			vehicle.license_plate = license_plate
            vehicle.state = state
            vehicle.make = make
            vehicle.model = model
			if params[:user_id].present?
				user = User.find_by(:id => params[:user_id])
				if user.nil?
					raise StandardError.new "A user does not exist with user ID #{params[:user_id]}"
				end
				vehicle.user_id = params[:user_id]
				if user.is_current?
					user.send_vehicle_information_update
				end
			else
				vehicle.user_id = @user.id
				if @user.is_current?
					@user.send_vehicle_information_update
				end
			end
			vehicle.save

			# notify that it worked
			flash(:success, 'Vehicle Addition Successful', "Your vehicle has been added.")
			if params[:user_id].present?
				redirect "/admin/users/#{params[:user_id]}/edit/"
			else
				redirect '/me/'
			end
		rescue => exception
			flash(:error, 'Vehicle Addition Failed', exception.message)
			redirect back
		end
	end
end

post '/vehicle/:vehicle_id/delete/?' do
	vehicle = Vehicle.find_by(:id => params[:vehicle_id])
	if vehicle.nil?
		# that vehicle does not exist
		flash(:danger, 'Not Found', 'That vehicle does not exist')
		if params[:user_id].present?
			redirect "/admin/users/#{params[:user_id]}/edit/"
		else
			redirect '/me/'
		end
	end
	
	begin
		if params[:user_id].present?
			user = User.find_by(:id => params[:user_id])
			if user.nil?
				raise StandardError.new "A user does not exist with user ID #{params[:user_id]}"
			end
			if user.is_current?
				user.send_vehicle_information_update
			end
		else
			if @user.is_current?
				@user.send_vehicle_information_update
			end
		end
		vehicle.destroy

		flash(:success, 'Vehicle Successfully Deleted', "Your vehicle has been deleted.")
		if params[:user_id].present?
			redirect "/admin/users/#{params[:user_id]}/edit/"
		else
			redirect '/me/'
		end
	rescue => exception
		flash(:error, 'Vehicle Deletion Failed', exception.message)
		redirect back
	end
end