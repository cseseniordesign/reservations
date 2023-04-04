require 'models/user'
require 'models/vehicle'

get '/vehicle/add/?' do
  require_login
  @breadcrumbs << {:text => 'My Account', :href => '/me/'} << {text: 'Add Vehicle'}

  erb :new_vehicle, :layout => :fixed, :locals => {
    :vehicle => Vehicle.new
  }
end

get '/vehicle/:vehicle_id/edit/?' do
    require_login
    @breadcrumbs << {:text => 'My Account', :href => '/me/'} << {text: 'Edit Vehicle'}
    vehicle = Vehicle.find_by(:id => params[:vehicle_id])
	if vehicle.nil?
		# that vehicle does not exist
		flash(:danger, 'Not Found', 'That vehicle does not exist')
		redirect '/me/'
	end
    erb :new_vehicle, :layout => :fixed, :locals => {
      :vehicle => vehicle
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
		redirect '/me/'
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
            vehicle.user_id = @user.id
			vehicle.save
			if @user.is_current?
				@user.send_vehicle_information_update
			end

			# notify that it worked
			flash(:success, 'Vehicle Update Successful', "Your vehicle has been updated.")
			redirect '/me/'
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
            vehicle.user_id = @user.id
			vehicle.save
			if @user.is_current?
				@user.send_vehicle_information_update
			end

			# notify that it worked
			flash(:success, 'Vehicle Addition Successful', "Your vehicle has been added.")
			redirect '/me/'
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
		redirect '/me/'
	end
	
	begin
		vehicle.destroy
		if @user.is_current?
			@user.send_vehicle_information_update
		end

		flash(:success, 'Vehicle Successfully Deleted', "Your vehicle has been deleted.")
		redirect '/me/'
	rescue => exception
		flash(:error, 'Vehicle Deletion Failed', exception.message)
		redirect back
	end
end