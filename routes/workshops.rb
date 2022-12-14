require 'models/resource'
require 'models/reservation'
require 'models/event'
require 'models/event_type'
require 'models/event_signup'
require 'models/space_hour'

get '/workshops/?' do
	@breadcrumbs << {:text => 'Workshops'}
	require_login

	workshop_id = EventType.find_by(:description => 'Advanced Skill-Based Workshop', :service_space_id => SS_ID).id
	events_advanced = Event.includes(:event_signups).where(:service_space_id => SS_ID, :event_type_id => workshop_id).
					where('start_time >= ?', Time.now).order(:start_time => :asc).all

	workshop_id = EventType.find_by(:description => 'Creation Workshop', :service_space_id => SS_ID).id
	events_creation = Event.includes(:event_signups).where(:service_space_id => SS_ID, :event_type_id => workshop_id).
					where('start_time >= ?', Time.now).order(:start_time => :asc).all

	workshop_id = EventType.find_by(:description => 'General Workshop', :service_space_id => SS_ID).id
	events_general = Event.includes(:event_signups).where(:service_space_id => SS_ID, :event_type_id => workshop_id).
					where('start_time >= ?', Time.now).order(:start_time => :asc).all

	erb :workshops, :layout => :fixed, :locals => {
		:events_advanced => events_advanced, :events_creation => events_creation, :events_general => events_general
	}
end

post '/workshops/sign_up/:event_id/?' do
	require_login

	# check that is a valid event
	workshop_id_advanced = EventType.find_by(:description => 'Advanced Skill-Based Workshop', :service_space_id => SS_ID).id
	workshop_id_creation ||= EventType.find_by(:description => 'Creation Workshop', :service_space_id => SS_ID).id
	workshop_id_general ||= EventType.find_by(:description => 'General Workshop', :service_space_id => SS_ID).id
	event = Event.find_by(:service_space_id => SS_ID, :event_type_id => workshop_id_advanced, :id => params[:event_id])
	event ||= Event.find_by(:service_space_id => SS_ID, :event_type_id => workshop_id_creation, :id => params[:event_id])
	event ||= Event.find_by(:service_space_id => SS_ID, :event_type_id => workshop_id_general, :id => params[:event_id])

	if event.nil?
		# that event does not exist
		flash(:danger, 'Not Found', "That event does not exist #{workshop_id}")
		redirect '/workshops/'
	end

	if !event.max_signups.nil? && event.signups.count >= event.max_signups
		# that event is full
		flash(:danger, 'Event Full', 'Sorry, that event is full.')
		redirect '/workshops/'
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => @user.full_name,
		:user_id => @user.id,
		:email => @user.email
	)

	body = <<EMAIL
<p>Thank you, #{@user.full_name} for signing up for #{event.title}. Don't forget that this workshop is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>We'll see you there!</p>

<p>Nebraska Innovation Studio</p>
EMAIL

	Emailer.mail(@user.email, "Nebraska Innovation Studio - #{event.title}", body)

	# flash a message that this works
	flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, #{event.title} is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}.")
	redirect '/workshops/'
end

