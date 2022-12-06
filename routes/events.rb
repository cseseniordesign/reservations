require 'models/event'
require 'models/event_signup'

MESSAGE_EVENT_NOT_FOUND = 'message_event_not_found'
MESSAGE_SIGNUP_NOT_ALLOWED = 'message_signup_not_allowed'

def flash_message(message)
    case message
        when MESSAGE_EVENT_NOT_FOUND
            flash(:danger, 'Not Found', 'That event does not exist')
        when MESSAGE_SIGNUP_NOT_ALLOWED
            flash(:danger, 'Signup Restricted', 'That event does not allow signup')
        else
            # invalid message, do nothing
    end
end

get '/events/:event_id/?' do
	# this is an event details page
	begin
		event = Event.includes(:location, :event_type, :event_signups).find(params[:event_id])
	rescue ActiveRecord::RecordNotFound => e
		not_found
	end

	@breadcrumbs << {:text => event.title}
	erb :event_details, :layout => :fixed, :locals => {
		:event => event
	}
end

get '/events/:event_id/sign_up_as_non_member/?' do
	event = Event.includes(:event_type).find_by(:id => params[:event_id])
	if event.nil?
		flash_message(MESSAGE_EVENT_NOT_FOUND)
		redirect '/calendar/'
	end
	if !event.signup_allowed_for_type?
	    flash_message(MESSAGE_SIGNUP_NOT_ALLOWED)
        redirect back
	end

	@breadcrumbs << {:text => event.title, :href => event.info_link}
	@breadcrumbs << {:text => 'Sign up as Non-Member'}
	erb :event_signup, :layout => :fixed, :locals => {
		:event => event
	}
end

post '/events/:event_id/sign_up_as_non_member/?' do
	event = Event.includes(:event_type).find_by(:id => params[:event_id])
	if event.nil?
		flash_message(MESSAGE_EVENT_NOT_FOUND)
		redirect '/calendar/'
	end
	if event.free_event_type?
		flash(:warning, 'Signup not required', 'This event is a Free Event and is open to anyone. No signup is required.')
		redirect event.info_link
	end
	if params[:name].trim.empty? || params[:email].trim.empty?
		flash(:danger, 'All Fields Required', 'Name and email are both required.')
		redirect back
	end

	if !event.signup_allowed_for_type?
	    flash_message(MESSAGE_SIGNUP_NOT_ALLOWED)
        redirect back
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => params[:name],
		:email => params[:email]
	)

	body = <<EMAIL
<p>Thank you, #{params[:name]} for signing up for #{event.title}. Don't forget that this event is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>We'll see you there!</p>

<p>Nebraska Innovation Studio</p>
EMAIL

	Emailer.mail(params[:email], "Nebraska Innovation Studio - #{event.title}", body)

	# flash a message that this works
	flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, #{event.title} is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}.")
	redirect event.info_link
end

post '/events/:event_id/sign_up/?' do
	require_login

	# check that is a valid event
	event = Event.includes(:event_type).find_by(:service_space_id => SS_ID, :id => params[:event_id])

	if event.nil?
		# that event does not exist
		flash_message(MESSAGE_EVENT_NOT_FOUND)
		redirect '/calendar/'
	end

	if !event.max_signups.nil? && event.signups.count >= event.max_signups
		# that event is full
		flash(:danger, 'Event Full', 'Sorry, that event is full.')
		redirect back
	end

	if !event.signup_allowed_for_type?
	    flash_message(MESSAGE_SIGNUP_NOT_ALLOWED)
        redirect back
	end

	if event.machine_training_event_type?
		check_membership
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => @user.full_name,
		:user_id => @user.id,
		:email => @user.email
	)

	if !event.free_event_type?
		body = <<EMAIL
<p>Thank you, #{@user.full_name} for signing up for #{event.title}. Don't forget that this event is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>We'll see you there!</p>

<p>Nebraska Innovation Studio</p>
EMAIL

		Emailer.mail(@user.email, "Nebraska Innovation Studio - #{event.title}", body)

		# flash a message that this works
		flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, #{event.title} is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}.")
		redirect back
	else
		# flash a message that this works
		flash(:success, "Event Marked", "This free event has been marked on your hoempage.")
		redirect back
	end
end

post '/events/:event_id/remove_signup/?' do
	require_login

	# get the event
	event = Event.includes(:event_type).where(:id => params[:event_id]).first

	# check that the signup exists
	signup = EventSignup.where(:event_id => params[:event_id], :user_id => @user.id).first

	if signup.nil?
		flash :alert, 'Not Found', 'That signup was not found.'
		redirect '/home/'
	end
	signup.delete

	header = event.free_event_type? ? 'Event Removed' : 'Signup Removed'
	message = event.free_event_type? ? "#{event.title} has been removed from your calendar." : "Your signup for #{event.title} has been removed."

	flash :success, header, message
	redirect '/home/'
end

post '/events/:event_id/confirm_trainer/?' do
	require_login

	# get the event
	event = Event.includes(:event_type).where(:id => params[:event_id]).first

	event.trainer_confirmed = 1
	event.save

	header = 'Training Confirmed'
	message = "Your training #{event.title} has been confirmed."

	flash :success, header, message
	redirect '/home/'
end