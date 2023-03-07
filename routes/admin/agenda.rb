before '/admin/agenda*' do
	unless has_permission?(Permission::SEE_AGENDA)
		raise Sinatra::NotFound
	end
end

get '/admin/agenda/' do
	@breadcrumbs << {:text => 'Agenda'}
	date = params[:date].nil? ? Time.now.midnight : Time.parse(params[:date])
	event_type = params[:event_type]

	reservations = Reservation.includes(:user, :resource, :event).in_day(date).order(:start_time).all.to_a
	reservations.select! do |res|
 		(!res.event.nil? && res.event.service_space_id == SS_ID) || (!res.resource.nil? && res.resource.service_space_id == SS_ID)
 	end

	events = Event.includes(:event_type).where(:service_space_id => SS_ID).in_day(date).order(:start_time)

	# Redefine the events variable if there is an event type filter applied
	unless event_type.nil? || event_type.length == 0
		events = Event.includes(:event_type).where(:service_space_id => SS_ID).in_day(date).order(:start_time).where(:event_type_id => event_type)
	end

	# get the hours for this day to show
	hours = SpaceHour.where(:service_space_id => SS_ID)
		.where('effective_date <= ?', date.utc.strftime('%Y-%m-%d %H:%M:%S'))
		.order(:effective_date => :desc, :id => :desc).all.to_a

	correct_hour = nil

	hours.each do |space_hour|
		if date.wday == space_hour.day_of_week && (space_hour.effective_date.in_time_zone.midnight == date.in_time_zone.midnight || (!space_hour.one_off && space_hour.effective_date.in_time_zone.midnight <= date.in_time_zone.midnight))
			correct_hour = space_hour
			break
		end
	end

	erb :'admin/agenda', :layout => :fixed, :locals => {
		:reservations => reservations,
		:events => events,
		:date => date,
		:space_hour => correct_hour,
		:event_type => event_type
	}
end

post '/admin/agenda/reservations/:reservation_id/remove/?' do
	reservation = Reservation.find_by(:id => params[:reservation_id])
	if reservation.nil?
		flash :error, 'Not Found', "Could not find that reservation."
		redirect '/admin/agenda/'
	end

	reservation.delete
	flash :success, 'Reservation Removed', "#{reservation.user.full_name}'s reservation for #{reservation.resource.name} has been removed."
	redirect '/admin/agenda/'
end