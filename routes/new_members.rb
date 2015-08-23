require 'models/event'
require 'models/event_signup'

get '/new_members/?' do
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id

    erb :new_members, :layout => :fixed, :locals => {
    	:events => Event.includes(:event_signups).where(:service_space_id => SS_ID, :event_type_id => new_member_orientation_id).all
    }
end

get '/new_members/sign_up/:event_id/?' do
	# check if this is a new member signup orientation
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id
	event = Event.includes(:event_signups).find_by(:service_space_id => SS_ID, :id => params[:event_id])
	if event.nil? || event.event_type_id != new_member_orientation_id
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/new_members/'
	end

	if event.signups.count >= 10
		# that event is full
		flash(:alert, 'This Orientation is Full', "Sorry, #{event.title} is full.")
		redirect '/new_members/'
	end

	erb :new_member_signup, :layout => :fixed, :locals => {
		:event => event
	}
end

post '/new_members/sign_up/:event_id/?' do
	# check if this is a new member signup orientation
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id
	event = Event.includes(:event_signups).find_by(:service_space_id => SS_ID, :id => params[:event_id])
	if event.nil? || event.event_type_id != new_member_orientation_id
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/new_members/'
	end

	if event.signups.count >= 10
		# that event is full
		flash(:alert, 'This Orientation is Full', "Sorry, #{event.title} is full.")
		redirect '/new_members/'
	end

	if params[:signup_password].trim != 'makerspace'
		flash(:alert, 'Incorrect Password', 'Please use the password provided in your email to sign up for this orientation.')
		redirect "/new_members/sign_up/#{params[:event_id]}/"
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => params[:name],
		:email => params[:email]
	)

	# flash a message that this works
	flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, orientation is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}.")
	redirect '/new_members/'
end

