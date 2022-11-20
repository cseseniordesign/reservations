require 'active_record'

class ExpirationReminder < ActiveRecord::Base
    def get_first_reminder
        first_reminder
    end

    def get_second_reminder
        second_reminder
    end
    
end