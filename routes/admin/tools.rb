require 'models/resource'
require 'models/permission'
require 'models/reservation'

NIS_TOOL_RESOURCE_CLASS_ID = 1

before '/admin/tools*' do
	unless has_permission?(Permission::MANAGE_RESOURCES)
		raise Sinatra::NotFound
	end
end

get '/admin/tools/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Tools'}

	tools = Resource.where(:service_space_id => SS_ID).order(:name).all.to_a
	tools.sort_by! {|tool| tool.category_name.downcase + tool.name.downcase + tool.model.downcase}
	erb :'admin/tools', :layout => :fixed, :locals => {
		:tools => tools
	}	
end

post '/admin/tools/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Tools'}
	tools = Resource.where(:service_space_id => SS_ID).order(:name).all.to_a

	# Revert tools INOP status when a pre-checked checkbox is unchecked
	tools.each do |tool|
		unless params.has_key?("INOP_#{tool.id}") && params["INOP_#{tool.id}"] == 'on' 
			if tool.INOP
				tool.INOP = false
				tool.save
			end 
		end	
	end
	
	#  Mark tool as INOP tool when checking the INOP checkbox
    params.each do |key, value|
        if key.start_with?('INOP_') && value == 'on'

            tool_id = key.split('INOP_')[1].to_i
			tool_record = Resource.find_by(:id => tool_id)

			if !tool_record.INOP 
				tool_record.INOP = true
				tool_record.save
			end
        end
    end

	# If a tool is marked INOP, email all users who have it reserved in the future. Once done, delete the reservation.
	reservations = Reservation.joins(:resource).
		where(:resources => {:service_space_id => SS_ID}).
		where('resources.INOP = ?', 1).
		where("user_id IS NOT NULL").
		where('start_time > ?', Time.now).
		order(:start_time).all

	reservations.each do |reservation|

		user_to_email = User.where('id = ?', reservation.user_id)

		user_to_email.each do |user|
			user.notify_user_of_broken_equipment(reservation)
		end

		# delete the reservation
		reservation.destroy
	end

	flash(:success, 'INOP Statuses Updated', "Tool INOP Statuses have been updated.")
	redirect back
	
end

get '/admin/tools/create/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Tools', :href => '/admin/tools/'} << {:text => 'Create Tool'}

	erb :'admin/edit_tool', :layout => :fixed, :locals => {
		:tool => Resource.new
	}
end

post '/admin/tools/create/?' do
	require_login

	tool = Resource.new
	tool.resource_class_id = NIS_TOOL_RESOURCE_CLASS_ID
	tool.name = params[:name]
	tool.category_id = params[:category_id]
	tool.description = params[:description]
	tool.service_space_id = SS_ID
	tool.needs_authorization = params.checked?('needs_authorization')
	tool.is_reservable = params.checked?('is_reservable')
	tool.time_slot_type = params[:time_slot_type]
	tool.minutes_per_reservation = params[:minutes_per_reservation]
	tool.min_minutes_per_reservation = params[:min_minutes_per_reservation]
	tool.max_minutes_per_reservation = params[:max_minutes_per_reservation]
	tool.increment_minutes_per_reservation = params[:increment_minutes_per_reservation]
	tool.needs_approval = false
	tool.max_reservations_per_slot = 5
	tool.max_reservations_per_user = params[:max_reservations_per_user]
	tool.save
	tool.set_field_data('model', params[:model])


	flash(:success, 'Tool Created', "Your tool #{tool.name} has been created.")
	redirect '/admin/tools/'
end

get '/admin/tools/:resource_id/edit/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Tools', :href => '/admin/tools/'} << {:text => 'Edit Tool'}

	# check that this is a valid tool
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

	erb :'admin/edit_tool', :layout => :fixed, :locals => {
		:tool => tool
	}
end

post '/admin/tools/:resource_id/edit/?' do
	require_login

	# check that this is a valid tool
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

    if params[:max_minutes_per_reservation].to_i > Reservation::MAX_MINUTES_PER_RESERVATION_LIMIT
        flash(:alert, 'Invalid Range Max', "The range max cannot be greater than #{Reservation::MAX_MINUTES_PER_RESERVATION_LIMIT} minutes.")
        redirect back
    end

	tool.name = params[:name]
	tool.category_id = params[:category_id]
	tool.description = params[:description]
	tool.needs_authorization = params.checked?('needs_authorization')
	tool.is_reservable = params.checked?('is_reservable')
	tool.time_slot_type = params[:time_slot_type]
	tool.minutes_per_reservation = params[:minutes_per_reservation]
	tool.min_minutes_per_reservation = params[:min_minutes_per_reservation]
	tool.max_minutes_per_reservation = params[:max_minutes_per_reservation]
	tool.increment_minutes_per_reservation = params[:increment_minutes_per_reservation]
	tool.max_reservations_per_user = params[:max_reservations_per_user]
	tool.save
	tool.set_field_data('model', params[:model])

	flash(:success, 'Tool Updated', "Your tool #{tool.name} has been updated.")
	redirect '/admin/tools/'
end

post '/admin/tools/:resource_id/delete/?' do
	require_login

	# check that this is a valid tool
	tool = Resource.find_by(:id => params[:resource_id], :service_space_id => SS_ID)
	if tool.nil?
		flash(:alert, 'Not Found', 'That tool does not exist.')
		redirect '/admin/tools/'
	end

	tool.destroy

	flash(:success, 'Tool Deleted', "Your tool #{tool.name} has been deleted. All reservations and permissions on this tool have also been removed.")
	redirect '/admin/tools/'
end