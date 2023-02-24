require 'models/reservation'
require 'models/event'
require 'routes/admin/events'
require 'models/alert'

get '/home/?' do
	require_login

	reservations = Reservation.joins(:resource).includes(:event).
		where(:resources => {:service_space_id => SS_ID}).
		where(:user_id => @user.id).
		where('end_time >= ?', Time.now).
		order(:start_time).all

	user_events = Event.includes(:event_type).joins(:event_signups).
		where(:event_signups => {:user_id => @user.id}).
		where('end_time >= ?', Time.now).
		order(:start_time).all

	trainer_events = Event.
		where(:events => {:trainer_id => @user.id}).
		where('end_time >= ?', Time.now).
		order(:start_time).all
	user_alerts = AlertSignup.joins(:alert).where('user_id = ?', @user.id)

	erb :home, :layout => :fixed, :locals => {
		:reservations => reservations,
		:events => user_events,
		:trainer_events => trainer_events,
		:user_alerts => user_alerts
		
	}
end

post '/home/:alert_signup/remove_signup/:alert_id/?' do
	require_login

	# check that this is a valid alert signup
	alert_signup = AlertSignup.find_by(:id => params[:alert_signup])
	alert = Alert.find_by(:id => params[:alert_id])
	if alert_signup.nil?
		flash(:alert, 'Not Found', 'That alert signup does not exist.')
		redirect '/home/'
	end

	alert_signup.destroy

	flash(:success, 'Unsubscribed', "You've unsubscribed from #{alert.name}.")
	redirect '/home/'
end

post '/home/add_all/:category_id/' do
	require_login
	user_alerts = AlertSignup.joins(:alert).where('user_id = ?', @user.id).to_a
	general_alerts = Alert.all.where('category_id = ?', params[:category_id]).to_a

	newAlerts = Array.new
	user_alerts.each do |alert|
        newAlerts.append(alert.alert_id)
    end
	# adding only the alerts that the user does not have
	general_alerts.each do |alert|
		unless newAlerts.include?(alert.id)
			user_alert = AlertSignup.create(user_id: @user.id, alert_id: alert.id)
		end
	end	

	case params[:category_id].to_i
	when Alert::ALERT_CATEGORY_GENERAL_ALERTS
		flash(:success, 'Added All General Alerts', "You've been signed up for all General Alerts.")
	when Alert::ALERT_CATEGORY_WOODSHOP_ALERTS
		flash(:success, 'Added All Woodshop Alerts', "You've been signed up for all Woodshop Alerts.")
	when Alert::ALERT_CATEGORY_METALSHOP_ALERTS
		flash(:success, 'Added All Metalshop Alerts', "You've been signed up for all Metalshop Alerts.")
	when Alert::ALERT_CATEGORY_DIGITAL_FABRICATION_ALERTS
		flash(:success, 'Added All Digital Fabrication Alerts', "You've been signed up for all Digital Fabrication Alerts.")
	when Alert::ALERT_CATEGORY_ART_ALERTS
		flash(:success, 'Added All Art Alerts', "You've been signed up for all Art Alerts.")
	end

	redirect '/home/'
end