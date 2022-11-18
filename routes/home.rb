require 'models/reservation'
require 'models/event'
require 'routes/admin/events'

get '/home/?' do
	reservations = Reservation.joins(:resource).includes(:event).
		where(:resources => {:service_space_id => SS_ID}).
		where(:user_id => @user.id).
		where('end_time >= ?', Time.now).
		order(:start_time).all

	events = Event.includes(:event_type).joins(:event_signups).
		# where(:event_signups => {:user_id => @user.id}).
		where('event_signups.user_id = ? OR events.trainer_id = ?', @user.id, @user.id). # THIS ISN'T WORKING. It's not showing events where I am listed as a trainer.
		where('end_time >= ?', Time.now).
		order(:start_time).all

	# trainer_events = Event.includes(:event_type).joins(:event_signups).
	# 	where(:event_signups => {:user_id => @user.id}).
	# 	where('end_time >= ?', Time.now).
	# 	order(:start_time).all

	erb :home, :layout => :fixed, :locals => {
		:reservations => reservations,
		:events => events
		# :trainer_events 
	}
end