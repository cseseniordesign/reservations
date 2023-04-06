require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/user'
require 'models/service_space'

SS_ID = ServiceSpace.where(:name => 'Innovation Studio').first.id

users_expiring_today = User.where(:service_space_id => SS_ID).where('expiration_date >= ? AND expiration_date < ?', Time.now - 1.days, Time.now).all
if users_expiring_today.count > 0
	body = "<p>Hello, the following users are expiring today and will need their parking information removed from passport parking:</p>"
	users_expiring_today.each do |user|
		body = body + "<p>Full Name: #{user.first_name} #{user.last_name}, Username: #{user.username}</p>"
	end
	Emailer.mail("innovationstudio@unl.edu", "Expiring Users' Parking Information Update", body, '', nil)
end