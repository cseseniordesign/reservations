require 'active_record'

class CheckIn < ActiveRecord::Base

    scope :in_day, ->(time) {
		today = time.in_time_zone.midnight
		tomorrow = (time.in_time_zone.midnight + 1.day + 1.hour).in_time_zone.midnight
		where('(datetime >= ? AND datetime < ?)', today.getutc, tomorrow.getutc)
	}

end