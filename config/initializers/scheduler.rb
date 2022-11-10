require 'highlander'    # prevents scheduler from running more than once
require 'rufus-scheduler'

scheduler = Rufus::Scheduler::singleton

scheduler.cron '0 12 * * * America/Chicago' do    # Every day at 12 pm Chicago time
    system("ruby ././scripts/email_expiring_users.rb")
end

# prevents scheduler from exiting
while 1 do
end
