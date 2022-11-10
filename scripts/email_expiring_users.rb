require_relative '../utils/language'
ENV['RACK_ENV'] ||= 'development'
# load the config file
require_relative '../utils/config_loader'

# set up the database connection
require 'utils/database'

# script-necessary things
require 'models/user'

# specify how many days before expiration
# a user should receive a reminder.
days_before_sending_first_reminder = 3
days_before_sending_second_reminder = 0

users_expiring_first_reminder = User.where(:service_space_id => 1).where('expiration_date >= ? AND expiration_date < ?', (Time.now + days_before_sending_first_reminder.days) - 1.days, Time.now + days_before_sending_first_reminder.days).all
users_expiring_second_reminder = User.where(:service_space_id => 1).where('expiration_date >= ? AND expiration_date < ?', (Time.now + days_before_sending_second_reminder.days) - 1.days, Time.now + days_before_sending_second_reminder.days).all

users_expiring_first_reminder.each do |user|
	user.send_membership_expiring_email
end

users_expiring_second_reminder.each do |user|
	user.send_membership_expiring_email
end