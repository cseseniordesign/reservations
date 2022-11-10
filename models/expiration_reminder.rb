require 'active_record'

class ExpirationReminder < ActiveRecord::Base
    def firstReminder
        first_reminder
    end

    def secondReminder
        second_reminder
    end
    
end