# start scheduler on new process
p = Proc.new do
    require 'rufus-scheduler'
    
    scheduler = Rufus::Scheduler::singleton
    
    scheduler.every '20s' do    # Every day at 12 pm Chicago time
        if Time.new.hour == 14
            system("ruby ././scripts/email_expiring_users.rb")
            system("ruby ././scripts/email_unconfirmed_trainers.rb")
        end
    end
    
    # prevents scheduler from exiting
    while 1 do
    end
end

fork { p.call }