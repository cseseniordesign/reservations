require 'models/reservation'
require 'models/event'
require 'routes/admin/events'

get '/home/?' do
	reservations = Reservation.joins(:resource).includes(:event).
		where(:resources => {:service_space_id => SS_ID}).
		where(:user_id => @user.id).
		where('end_time >= ?', Time.now).
		order(:start_time).all

	# events = Event.includes(:event_type).joins(:event_signups).	# Original; this works.
	user_events = Event.includes(:event_type).joins(:event_signups). # because of the join, you will not see events that a trainer is assigned to unless people have signed up for that event.
	# user_events = Event.includes(:event).includes(:event_type).joins(:event_signups).
	# user_events = Event.includes(:trainer).includes(:event_type).joins(:event_signups).
	# user_events = Event.includes(:trainer_id).includes(:event_type).joins(:event_signups).
	# user_events = Event.includes(:events).includes(:event_type).joins(:event_signups).
	# user_events = Event.includes(event).includes(:event_type).joins(:event_signups).
	# user_events = Event.includes(events).includes(:event_type).joins(:event_signups).
	# user_events = Event.includes('routes/admin/events').includes(:event_type).joins(:event_signups).
	# events = Event.includes(events).includes(:event_type).joins(:event_signups).
	# events = Event.includes(:event_type).
	# events = Event.includes(:event_type).includes(:event_signups).
	# events = Event.includes(:events).joins(:event_type).joins(:event_signups).
	# events = Event.includes(:events).includes(:event_type).joins(:event_signups).
	# events = Event.includes(:trainer).includes(:event_type).joins(:event_signups).
	# events = Event.
		# where(:event_signups => {:user_id => @user.id}).	# Original; this works.
		# where(:trainer_id => {:user_id => @user.id}).
		# where(:trainer_id => @user.id).
		# where('select * from events where trainer_id = 3489').
		# where('trainer_id = ?', @user.id).
		# where('events.trainer_id = 3489').
		# where('? = 3489', @trainer_id).
		# where('? = ?', @trainer_id, @user.id).
		# where('events.trainer_id = 3489').
		# where('trainer_id = 3489').
		# where('trainer_id = ?', @user.id).
		# where('events.trainer_id = ?', @user.id).
		where('event_signups.user_id = ? OR events.trainer_id = ?', @user.id, @user.id). # THIS ISN'T WORKING. It's not showing events where I am listed as a trainer.
		# where('event_signups.user_id = 3489 OR events.trainer_id = 3489').
		# where('event_signups.user_id = 3489 OR events.trainer_id = 3489').
		# where('event_signups.user_id = 3489 OR events.trainer.id = 3489').
		# where('event_signups.user_id = 3489 OR trainer_id = 3489').
		# where('event_signups.user_id = 3489 OR ? = 3489', :trainer_id).
		# where('? = 3489 OR trainer_id = 3489', Event.(:event_signups)).	# did not try this yet
		# where('events.trainer_id = 3489').
		# where('event_signups.user_id = 3489').
		# where('(event_signups.user_id = 3489) OR (reservation.events.trainer_id = 3489)').
		# where('(event_signups.user_id = 3489) OR (trainer_id FROM reservation.events = 3489)').
		where('end_time >= ?', Time.now).	# Original; this works.
		order(:start_time).all				# Original; this works.

	# trainer_events = Event.includes(:event_type).joins(:event_signups).
	# 	where(:event_signups => {:user_id => @user.id}).
	# 	where('end_time >= ?', Time.now).
	# 	order(:start_time).all

	erb :home, :layout => :fixed, :locals => {
		:reservations => reservations,
		:events => user_events
		# :trainer_events 
	}
end