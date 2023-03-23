require 'highlander'    # prevents scheduler from running more than once
require 'rufus-scheduler'

scheduler = Rufus::Scheduler::singleton

scheduler.cron '0 12 * * * America/Chicago' do    # Every day at 12 pm Chicago time
    if Time.new.hour == 12
        system("ruby ././scripts/email_expiring_users.rb")
        system("ruby ././scripts/email_unconfirmed_trainers.rb")
    end
end

scheduler.cron '0 22 * * * America/Chicago' do    # Every day at 10 pm Chicago time
    if Time.new.hour == 22
        system("ruby ././scripts/email_expiring_users_vehicle_update.rb")
    end
end

# prevents scheduler from exiting
while 1 do
end
