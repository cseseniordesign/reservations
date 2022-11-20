require 'models/event'
require 'models/event_signup'
require 'classes/emailer'
require 'recaptcha'

Recaptcha.configure do |config|
	config.site_key = CONFIG['reCaptcha']['site_key']
	config.secret_key = CONFIG['reCaptcha']['secret_key']
end

include Recaptcha::Adapters::ControllerMethods
include Recaptcha::Adapters::ViewMethods


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
		:event => event,
		:recaptcha => Recaptcha.recaptcha_tags
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

	if !verify_recaptcha
		flash(:alert, 'Google Recaptcha Verification failed', 'please try again.')
		redirect '/new_members/'
	end

	EventSignup.create(
		:event_id => params[:event_id],
		:name => params[:first_name] + " " + params[:last_name],
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

		params.delete("g-recaptcha-response")
		params.delete("event_id")
		user = User.new(params)

		# Username parameters:
		# First letter of first name
		# First 5 letters of last name
		# New usernames, append a number on the end starting at 2.
		username_parameters = params[:first_name][0].downcase + params[:last_name][0...5].downcase

		# Create a new user name based on the username_parameters, if the name already exists, increment the name.
		counter = 2
		while true
			if User.find_by(:username => "#{username_parameters + counter.to_s}").nil?
				user.username = "#{username_parameters + counter.to_s}"
				break
			end
			counter = counter + 1
		end

		user.space_status = 'expired'
		user.service_space_id = SS_ID
		user.save

		# flash a message that this works
		flash(:success, "You're signed up!", "Thanks for signing up! Don't forget, orientation is #{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}. Check your email for more information about the event and where to park.")
		redirect '/new_members/'
	end
  
end

# Code copied from Recaptcha::Adapters::ControllerMethods to resolve issue of this method being private

def verify_recaptcha(options = {})
	options = {model: options} unless options.is_a? Hash
	return true if Recaptcha.skip_env?(options[:env])

	model = options[:model]
	attribute = options.fetch(:attribute, :base)
	recaptcha_response = options[:response] || recaptcha_response_token(options[:action])

	begin
	  verified = if Recaptcha.invalid_response?(recaptcha_response)
		false
	  else
		unless options[:skip_remote_ip]
		  remoteip = (request.respond_to?(:remote_ip) && request.remote_ip) || (env && env['REMOTE_ADDR'])
		  options = options.merge(remote_ip: remoteip.to_s) if remoteip
		end

		success, @_recaptcha_reply =
		  Recaptcha.verify_via_api_call(recaptcha_response, options.merge(with_reply: true))
		success
	  end

	  if verified
		flash.delete(:recaptcha_error) if recaptcha_flash_supported? && !model
		true
	  else
		recaptcha_error(
		  model,
		  attribute,
		  options.fetch(:message) { Recaptcha::Helpers.to_error_message(:verification_failed) }
		)
		false
	  end
	rescue Timeout::Error
	  if Recaptcha.configuration.handle_timeouts_gracefully
		recaptcha_error(
		  model,
		  attribute,
		  options.fetch(:message) { Recaptcha::Helpers.to_error_message(:recaptcha_unreachable) }
		)
		false
	  else
		raise RecaptchaError, 'Recaptcha unreachable.'
	  end
	rescue StandardError => e
	  raise RecaptchaError, e.message, e.backtrace
	end
  end

  def verify_recaptcha!(options = {})
	verify_recaptcha(options) || raise(VerifyError)
  end

  def recaptcha_reply
	@_recaptcha_reply if defined?(@_recaptcha_reply)
  end

  def recaptcha_error(model, attribute, message)
	if model
	  model.errors.add(attribute, message)
	elsif recaptcha_flash_supported?
	  flash[:recaptcha_error] = message
	end
  end

  def recaptcha_flash_supported?
	request.respond_to?(:format) && request.format == :html && respond_to?(:flash)
  end

  # Extracts response token from params. params['g-recaptcha-response-data'] for recaptcha_v3 or
  # params['g-recaptcha-response'] for recaptcha_tags and invisible_recaptcha_tags and should
  # either be a string or a hash with the action name(s) as keys. If it is a hash, then `action`
  # is used as the key.
  # @return [String] A response token if one was passed in the params; otherwise, `''`
  def recaptcha_response_token(action = nil)
	response_param = params['g-recaptcha-response-data'] || params['g-recaptcha-response']
	response_param = response_param[action] if action && response_param.respond_to?(:key?)

	if response_param.is_a?(String)
	  response_param
	else
	  ''
	end
  end

