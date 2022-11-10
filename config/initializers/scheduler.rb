require 'highlander'    # prevents scheduler from running more than once
require 'rufus-scheduler'

scheduler = Rufus::Scheduler::singleton

scheduler.cron '0 12 * * *' do    # Every day at 12 pm
    system("ruby ././scripts/email_expiring_users.rb")
end

while 1 do
end
