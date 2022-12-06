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


trainers_to_notify = User.
    where(:service_space_id => SS_ID).
    where('is_trainer = 1').where('
    EXISTS(SELECT *
        FROM events
        WHERE service_space_id = ?
        AND start_time > ?
        AND trainer_id > 0
        AND trainer_confirmed = 0
        AND events.trainer_id = users.id)', SS_ID, Time.now).all


trainers_to_notify.each do |user|
    user.send_trainer_confirmation_reminder
end