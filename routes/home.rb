require 'models/reservation'
require 'models/event'
require 'routes/admin/events'

get '/home/?' do
	reservations = Reservation.joins(:resource).includes(:event).
		where(:resources => {:service_space_id => SS_ID}).
		where(:user_id => @user.id).
		where('end_time >= ?', Time.now).
		order(:start_time).all

	user_events = Event.includes(:event_type).joins(:event_signups).	# Original; this works.
	# user_events = Event.includes(:event_type).joins(:event_signups). # because of the join, you will not see events that a trainer is assigned to unless people have signed up for that event.
		where(:event_signups => {:user_id => @user.id}).	# Original; this works.
		# where('event_signups.user_id = ? OR events.trainer_id = ?', @user.id, @user.id).
		where('end_time >= ?', Time.now).	# Original; this works.
		order(:start_time).all				# Original; this works.

	trainer_events = Event.
		where(:events => {:trainer_id => @user.id}).
		# where('events.trainer_id = ?', @user.id).
		where('end_time >= ?', Time.now).	# Original; this works.
		order(:start_time).all				# Original; this works.

	# trainer_events = Event.includes(:event_type).joins(:event_signups).
	# 	where(:event_signups => {:user_id => @user.id}).
	# 	where('end_time >= ?', Time.now).
	# 	order(:start_time).all

	erb :home, :layout => :fixed, :locals => {
		:reservations => reservations,
		# :events => user_events
		:events => user_events,
		:trainer_events => trainer_events
		# :trainer_events 
	}
end