require 'models/event'
require 'models/event_signup'
require 'classes/emailer'

get '/new_members/?' do
	@breadcrumbs << {:text => 'New Members'}
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id

    erb :new_members, :layout => :fixed, :locals => {
    	:events => Event.includes(:event_signups).where(:service_space_id => SS_ID, :event_type_id => new_member_orientation_id).where('start_time >= ?', Time.now).order(:start_time => :asc).all
    }
end

get '/new_members/sign_up/:event_id/?' do
	@breadcrumbs << {:text => 'New Members', :href => '/new_members/'} << {text: 'Sign Up'}

	# check if this is a new member signup orientation
	new_member_orientation_id = EventType.find_by(:description => 'New Member Orientation', :service_space_id => SS_ID).id
	event = Event.includes(:event_signups).find_by(:service_space_id => SS_ID, :id => params[:event_id])
	if event.nil? || event.event_type_id != new_member_orientation_id
		# that event does not exist
		flash(:danger, 'Not Found', 'That event does not exist')
		redirect '/new_members/'
	end

	if !event.max_signups.nil? && event.signups.count >= event.max_signups
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

	if !event.max_signups.nil? && event.signups.count >= event.max_signups
		# that event is full
		flash(:alert, 'This Orientation is Full', "Sorry, #{event.title} is full.")
		redirect '/new_members/'
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => params[:name],
		:email => params[:email]
	)

	body = <<EMAIL
<p>Thank you, #{params[:name]} for signing up for #{event.title}. Don't forget that the event is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>Our main entrance is on the northwest side of the Innovation Commons building on 19th St. just off Transformation Drive. Our address is 2021 Transformation Drive, Suite 1500, Entrance B.</p>

<p>For parking, use our <a href="https://innovationstudio-manager.unl.edu/pdf/new-member-orientation-parking-map.pdf">new member orientation parking</a>. Vehicles parked at any other location will be ticketed $50.00.</p>

<p>We'll see you there!</p>

<p>Nebraska Innovation Studio</p>
EMAIL

	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i

	if 	!VALID_EMAIL_REGEX.match(params[:email])
		flash(:danger, "Invalid Email", "Your email address didn't match any known email")
		redirect "new_members/sign_up/#{params[:event_id]}"
	else
		Emailer.mail(params[:email], "Nebraska Innovation Studio - #{event.title}", body)

		# flash a message that this works
		flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, orientation is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}. Check your email for more information about the event and where to park.")
		redirect '/new_members/'
	end
end

