require 'rest-client'
require 'models/event'
require 'models/event_type'
require 'models/location'
require 'models/resource'
require 'models/preset_event'

before '/admin/events*' do
	unless has_permission?(Permission::MANAGE_EVENTS) || has_permission?(Permission::EVENTS_ADMIN_READ_ONLY)
		raise Sinatra::NotFound
	end
end

before '/admin/events/:event_id/(create|edit|delete)*?' do
    unless has_permission?(Permission::MANAGE_EVENTS)
        raise Sinatra::NotFound
    end
end

get '/admin/events/?' do
	@breadcrumbs << {:text => 'Admin Events'}
	page = params[:page]
	page = page.to_i >= 1 ? page.to_i : 1
	page_size = 10
	tab = ['upcoming', 'past'].include?(params[:tab]) ? params[:tab] : 'upcoming'
	preset_events = PresetEvents.order(event_name: :asc).all.to_a

	case tab
	when 'past'
		where_clause = 'start_time < ?', Time.now
		order_clause = {:start_time => :desc}
	else
		where_clause = 'start_time >= ?', Time.now
		order_clause = {:start_time => :asc}
	end

	iterator = Event.includes(:event_signups).where(:service_space_id => SS_ID).where(where_clause)
	
	erb :'admin/events', :layout => :fixed, :locals => {
		:events => iterator.order(order_clause).limit(page_size).offset((page-1)*page_size).all,
		:total_pages => (iterator.count.to_f / page_size).ceil,
		:page => page,
		:tab => tab,
		:preset_events => preset_events
	}
end

get '/admin/events/:event_id/signup_list/?' do
	@breadcrumbs << {:text => 'Admin Events', :href => '/admin/events/'} << {text: 'Signup List'}
	event = Event.includes(:event_signups).find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

	erb :'admin/signup_list', :layout => :fixed, :locals => {
		:event => event
	}
end

get '/admin/events/create/?' do
	@breadcrumbs << {:text => 'Admin Events', :href => '/admin/events/'} << {text: 'Create Event'}
	tools = Resource.where(:service_space_id => SS_ID, :is_reservable => true).order(:name => :asc).all.to_a
	tools.sort_by! {|tool| tool.category_name.downcase + tool.name.downcase + tool.model.downcase}
	if Integer(params[:preset_id]) == 0
		erb :'admin/new_event', :layout => :fixed, :locals => {
			:event => Event.new,
			:types => EventType.where(:service_space_id => SS_ID).all,
			:trainers => User.where(:is_trainer => 1).all,
			:locations => Location.where(:service_space_id => SS_ID).all,
			:tools => tools,
			:on_unl_events => false,
			:on_main_calendar => false,
			:duration => 0
		}
	else
		preset = PresetEvents.find_by(:id => params[:preset_id])
		event = Event.new
		event.title = preset.event_name
		event.description = preset.description
		event.event_type_id = preset.event_type_id
		event.max_signups = preset.max_signups
		erb :'admin/new_event', :layout => :fixed, :locals => {
			:event => event,
			:types => EventType.where(:service_space_id => SS_ID).all,
			:trainers => User.where(:is_trainer => 1).all,
			:locations => Location.where(:service_space_id => SS_ID).all,
			:tools => tools,
			:on_unl_events => false,
			:on_main_calendar => false,
			:duration => preset.duration
		}
	end	
end

post '/admin/events/create/?' do

	if params[:location] == 'new'
		# this is a new location, we must create it!
		location = Location.create(params[:new_location].merge({
			:service_space_id => SS_ID
		}))
		params[:location] = location.id
	end

	event = Event.new
	event.set_image_data(params)
	event.set_data(params)

	if params.has_key?('reserve_tool') && params['reserve_tool'] == 'on'
        # check for possible other reservations during this time period
        date = event.start_time.midnight.in_time_zone
        params[:tools].each do |tool_id|
            other_reservations = Reservation.where(:resource_id => tool_id).in_day(date).all
            other_reservations.each do |reservation|
                if event.start_time.in_time_zone < reservation.end_time.in_time_zone && reservation.start_time.in_time_zone < event.end_time.in_time_zone
                    event.delete
                    flash :alert, "A tool is being used.", "Sorry, a selected tool is reserved during that time period. Please try different day or time."
                    redirect back
                end
            end

            # we need to create a reservation for the tool on the appropriate time
            Reservation.create(
                :resource_id => tool_id,
                :event_id => event.id,
                :start_time => event.start_time,
                :end_time => event.end_time,
                :is_training => true,
                :user_id => nil
            )
        end
	end

	if params.checked?('export_to_unl_events')
		# first create the location, if necessary
		if event.location.unl_events_id.nil?
			post_params = event.location.attributes.merge(:api_token => CONFIG['unl_events_api_token'])
			RestClient.post("#{CONFIG['unl_events_api_url']}location/create/", post_params) do |response, request, result|
				case response.code
				when 200
					event.location.unl_events_id = JSON.parse(response.body)['id']
					event.location.save
				else
					flash :error, 'Location Not Posted to UNL Events', "We had an issue creating the location on UNL Events. Please go to events.unl.edu/manager to create your event."
				end
			end
		end

		# send the event up
		post_params = {
			:title => params[:title],
			:description => params[:description],
			:trainer => event.trainer_id,
			:location => event.location.unl_events_id,
			:start_time => event.start_time.in_time_zone.strftime('%Y-%m-%d %H:%M:%S'),
			:end_time => event.end_time.in_time_zone.strftime('%Y-%m-%d %H:%M:%S'),
			:api_token => CONFIG['unl_events_api_token']
		}

		if params.checked?('consider_for_unl_main')
			post_params['send_to_main'] =  'yes'
		end

		RestClient.post("#{CONFIG['unl_events_api_url']}#{CONFIG['unl_events_api_calendar']}/create/", post_params) do |response, request, result|
			case response.code
			when 200
				flash :success, 'Event Posted to UNL Events', "The event can now be found on the NIS UNL Events calendar."
				event.unl_events_id = JSON.parse(response.body)['id']
				event.save
			else
				flash :error, 'Event Not Posted to UNL Events', "There was a problem posting to UNL Events. You should check out your UNL Events calendar to see if your event made it."
			end
		end
	end

	# notify that it worked
	flash(:success, 'Event Created', "Your #{event.type.description}: #{event.title} has been created.")
	redirect '/admin/events/'
end

get '/admin/events/:event_id/edit/?' do
	@breadcrumbs << {:text => 'Admin Events', :href => '/admin/events/'} << {text: 'Edit Event'}
	event = Event.includes(:event_type, :location, :reservation => :resource).find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

	on_unl_events = false
	on_main_calendar = false
	unless event.unl_events_id.nil?
		get_params = {
			:api_token => CONFIG['unl_events_api_token']
		}
		RestClient.get("#{CONFIG['unl_events_api_url']}#{CONFIG['unl_events_api_calendar']}/event/#{event.unl_events_id}/", {:params => get_params}) do |response, request, result, &block|
			if response.code == 200
				on_unl_events = true
				if JSON.parse(response.body)['on_main_calendar']
					on_main_calendar = true
				end
			end
		end
	end

	tools = Resource.where(:service_space_id => SS_ID, :is_reservable => true).order(:name => :asc).all.to_a
	tools.sort_by! {|tool| tool.category_name.downcase + tool.name.downcase + tool.model.downcase}
	erb :'admin/new_event', :layout => :fixed, :locals => {
		:event => event,
		:types => EventType.where(:service_space_id => SS_ID).all,
		:trainers => User.where(:is_trainer => 1).all,
		:locations => Location.where(:service_space_id => SS_ID).all,
		:tools => tools,
		:on_unl_events => on_unl_events,
		:on_main_calendar => on_main_calendar
	}
end

post '/admin/events/:event_id/edit/?' do
	event = Event.find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

    # remember original start/end times
    original_event_start_time = event.start_time
    original_event_end_time = event.end_time

	if params[:location] == 'new'
		# this is a new location, we must create it!
		location = Location.create(params[:new_location].merge({
			:service_space_id => SS_ID
		}))
		params[:location] = location.id
	end

	if params.checked?('remove_image')
		event.remove_image_data
	else
		event.set_image_data(params)
	end
	event.set_data(params)

	# check the tool reservation for this
	checked = params.checked?('reserve_tool')

    if (checked)
        # check for possible other reservations during this time period
        date = event.start_time.midnight.in_time_zone
        params[:tools].each do |tool_id|
            other_reservations = Reservation.where(:resource_id => tool_id).in_day(date).all
            other_reservations.each do |reservation|
                # ignore reservations for same the event
                next if reservation.event_id == event.id

                if event.start_time.in_time_zone < reservation.end_time.in_time_zone && reservation.start_time.in_time_zone < event.end_time.in_time_zone
                    # reset event times since reservation failed
                    event.update(start_time: original_event_start_time, end_time: original_event_end_time)

                    # show error and display event form
                    flash :alert, "A tool is being used.", "Sorry, a selected tool is reserved during that time period. Please try different day or time."
                    redirect back
                end
            end
        end
    end

    if event.has_reservation && checked
        # create or update selected tool reservations
        params[:tools].each do |tool_id|
            if event.has_tool_reservation(tool_id)
                # update the reservation
                event.reservation.update(
                    :resource_id => params[tool_id],
                    :event_id => event.id,
                    :start_time => event.start_time,
                    :end_time => event.end_time,
                    :is_training => true,
                    :user_id => nil
                )
            else
                # create the reservation
                Reservation.create(
                    :resource_id => tool_id,
                    :event_id => event.id,
                    :start_time => event.start_time,
                    :end_time => event.end_time,
                    :is_training => true,
                    :user_id => nil
                )
            end
        end

        # remove any old tool reservations
        event.reservation.each do |r|
            if !r.resource.nil? && !params[:tools].include?(r.resource.id)
                r.delete
            end
        end
    elsif event.has_reservation && !checked
        # remove all event reservations
        event.reservation.each do |r|
            r.delete
        end
    elsif !event.has_reservation && checked
        params[:tools].each do |tool_id|
            # create the reservation
            Reservation.create(
                :resource_id => tool_id,
                :event_id => event.id,
                :start_time => event.start_time,
                :end_time => event.end_time,
                :is_training => true,
                :user_id => nil
            )
        end
    end

	if params.checked?('export_to_unl_events')
		on_unl_events = false
		unless event.unl_events_id.nil?
			get_params = {
				:api_token => CONFIG['unl_events_api_token']
			}
			RestClient.get("#{CONFIG['unl_events_api_url']}#{CONFIG['unl_events_api_calendar']}/event/#{event.unl_events_id}/", {:params => get_params}) do |response, request, result, &block|
				if response.code == 200
					on_unl_events = true
					if JSON.parse(response.body)['on_main_calendar']
						on_main_calendar = true
					end
				end
			end
		end

		if !on_unl_events
			# first create the location, if necessary
			if event.location.unl_events_id.nil?
				post_params = event.location.attributes.merge(:api_token => CONFIG['unl_events_api_token'])
				RestClient.post("#{CONFIG['unl_events_api_url']}location/create/", post_params) do |response, request, result|
					case response.code
					when 200
						event.location.unl_events_id = JSON.parse(response.body)['id']
						event.location.save
					else
						flash :error, 'Location Not Posted to UNL Events', "We had an issue creating the location on UNL Events. Please go to events.unl.edu/manager to create your event."
					end
				end
			end

			# send the event up
			post_params = {
				:title => params[:title],
				:description => params[:description],
				:trainer => event.trainer_id,
				:location => event.location.unl_events_id,
				:start_time => event.start_time.in_time_zone.strftime('%Y-%m-%d %H:%M:%S'),
				:end_time => event.end_time.in_time_zone.strftime('%Y-%m-%d %H:%M:%S'),
				:api_token => CONFIG['unl_events_api_token']
			}

			if params.checked?('consider_for_unl_main')
				post_params['send_to_main'] =  'yes'
			end

			RestClient.post("#{CONFIG['unl_events_api_url']}#{CONFIG['unl_events_api_calendar']}/create/", post_params) do |response, request, result|
				case response.code
				when 200
					flash :success, 'Event Posted to UNL Events', "The event can now be found on the NIS UNL Events calendar."
					event.unl_events_id = JSON.parse(response.body)['id']
					event.save
				else
					flash :error, 'Event Not Posted to UNL Events', "There was a problem posting to UNL Events. You should check out your UNL Events calendar to see if your event made it."
				end
			end
		else
			post_params = {
				:title => params[:title],
				:description => params[:description],
				:api_token => CONFIG['unl_events_api_token']
			}

			if params.checked?('consider_for_unl_main')
				post_params['send_to_main'] = 'yes'
			end

			RestClient.post("#{CONFIG['unl_events_api_url']}#{CONFIG['unl_events_api_calendar']}/event/#{event.unl_events_id}/", post_params) do |response, request, result, &block|
				case response.code
				when 200
					flash :success, 'Event Posted to UNL Events', "The event details were updated on the NIS UNL Events calendar."
					event.unl_events_id = JSON.parse(response.body)['id']
					event.save
				else
					flash :error, 'Event Not Posted to UNL Events', "There was a problem posting to UNL Events. You should check out your UNL Events calendar to see if your event is OK."
				end
			end
		end
	end

	# notify that it worked
	flash(:success, 'Event Updated', "Your #{event.type.description}: #{event.title} has been updated.")
	redirect '/admin/events/'
end

post '/admin/events/:event_id/delete/?' do
	event = Event.find_by(:id => params[:event_id], :service_space_id => SS_ID)
	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/admin/events/'
	end

	event.destroy

	flash(:success, 'Event Deleted', "Your event #{event.title} has been deleted. All signups on this event have also been removed, and if a reservation was attached, it also has been removed.")
	redirect '/admin/events/'
end

get '/admin/events/presets/?' do
	@breadcrumbs << {:text => 'Manage Event Presets', :href => '/admin/events/presets'}
	preset_events = PresetEvents.order(event_name: :asc).all.to_a
	event_type_objects = EventType.where(:service_space_id => SS_ID)
	event_types = {}
	event_type_objects.each do |type|
		event_types[type.id] = type.description
	end
	
	erb :'admin/event_presets', :layout => :fixed, :locals => {
		:preset_events => preset_events,
		:event_types => event_types
	}
end

get '/admin/events/presets/create/?' do
	@breadcrumbs << {:text => 'Manage Event Presets', :href => '/admin/events/presets/'}  << {text: 'Create Preset Event'}
	event_types = EventType.where(:service_space_id => SS_ID).all
	tools = Resource.where(:service_space_id => SS_ID).order(:name).all.to_a
    tools.sort_by! {|tool| tool.category_name.downcase + tool.name.downcase + tool.model.downcase}
	
	erb :'admin/new_preset_event', :layout => :fixed, :locals => {
		:preset_event => PresetEvents.new,
		:event_types => event_types,
		:tools => tools
	}
end

post '/admin/events/presets/create/?' do
	preset = PresetEvents.new
	name = params[:name]
	description = params[:description]
	type = params[:type]
	max_signups = params[:max_signups]
	duration = params[:duration]

	if name.blank? || description.blank? || type.to_i == 0 || duration.to_i == 0
		flash(:error, 'Preset Event Creation Failed', "Please fill out all required fields.")
		redirect back
	else
		begin
			if !params.checked?('limit_signups')
				max_signups = nil
			end

			preset.event_name = name
			preset.description = description
			preset.event_type_id = type
			preset.max_signups = max_signups
			preset.duration = duration
			preset.save

			# tie the tools that are checked to the preset event
			params.each do |key, value|
				if key.start_with?('tool_') && value == 'on'
					id = key.split('tool_')[1].to_i
					PresetEventsHasResource.create(
						:preset_events_id => preset.id,
						:resources_id => id
					)
				end
			end

			# notify that it worked
			flash(:success, 'Preset Event Created', "Your preset event #{preset.event_name} has been created.")
			redirect '/admin/events/presets'
		rescue => exception
			flash(:error, 'Preset Event Creation Failed', exception.message)
			redirect back
		end
	end
end

get '/admin/events/presets/:preset_id/edit/?' do
	@breadcrumbs << {:text => 'Manage Event Presets', :href => '/admin/events/presets/'}  << {text: 'Edit Preset Event'}
	event_types = EventType.where(:service_space_id => SS_ID).all
	preset = PresetEvents.find_by(:id => params[:preset_id])
	if preset.nil?
		# that preset does not exist
		flash(:danger, 'Not Found', 'That preset event does not exist')
		redirect '/admin/events/presets'
	end

	tools = Resource.where(:service_space_id => SS_ID).order(:name).all.to_a
    tools.sort_by! {|tool| tool.category_name.downcase + tool.name.downcase + tool.model.downcase}
	
	erb :'admin/new_preset_event', :layout => :fixed, :locals => {
		:preset_event => preset,
		:event_types => event_types,
		:tools => tools
	}
end

post '/admin/events/presets/:preset_id/edit/?' do
	name = params[:name]
	description = params[:description]
	type = params[:type]
	limit_signups = params[:limit_signups]
	max_signups = params[:max_signups]
	duration = params[:duration]

	preset = PresetEvents.find_by(:id => params[:preset_id])

	# make sure preset exists
	if preset.nil?
		flash(:danger, 'Not Found', 'That preset event does not exist')
		redirect '/admin/events/presets'
	end

	# make sure all required fields are supplied
	if name.blank? || description.blank? || type.to_i == 0 || duration.to_i == 0
		flash(:error, 'Preset Event Update Failed', "Please fill out all required fields.")
		redirect back
	else
		# all required information is present so update the preset
		if !params.checked?('limit_signups')
			max_signups = nil
		end

		begin
			preset.update(event_name: name, description: description, event_type_id: type, max_signups: max_signups, duration: duration)
		
			# check for removed tools
			preset.get_resource_ids.each do |resource_id|
				unless params.has_key?("tool_#{resource_id}") && params["tool_#{resource_id}"] == 'on'
					PresetEventsHasResource.where(:preset_events_id => preset.id, :resources_id => resource_id).delete_all
				end
			end
		
			# add new tools that are checked
			params.each do |key, value|
				if key.start_with?('tool_') && value == 'on'
					id = key.split('tool_')[1].to_i
					# check if the preset event already has this tool and if not then add it
					unless preset.get_resource_ids.include?(id)
						PresetEventsHasResource.create(
							:preset_events_id => preset.id,
							:resources_id => id
						)
					end
				end
			end

			# notify that it worked
			flash(:success, 'Preset Event Updated', "Your preset event #{preset.event_name} has been updated.")
			redirect '/admin/events/presets'
		rescue => exception
			flash(:error, 'Preset Event Update Failed', exception.message)
			redirect back
		end
	end
end

post '/admin/events/presets/:preset_id/delete/?' do
	preset = PresetEvents.find_by(:id => params[:preset_id])
	if preset.nil?
		# that preset does not exist
		flash(:danger, 'Not Found', 'That preset event does not exist')
		redirect '/admin/events/presets'
	end
	
	begin
		preset.get_resource_ids.each do |resource_id|
			PresetEventsHasResource.where(:preset_events_id => preset.id, :resources_id => resource_id).delete_all
		end
		preset.destroy
		flash(:success, 'Preset Event Deleted', "Your preset event #{preset.event_name} has been deleted.")
		redirect '/admin/events/presets'
	rescue => exception
		flash(:error, 'Preset Event Deletion Failed', exception.message)
		redirect back
	end
end