require 'models/user'
require 'models/resource'
require 'models/permission'
require 'models/event'
require 'csv'
require 'date'

get '/export/?' do
    user_events = Event.includes(:event_type).joins(:event_signups).
		where(:event_signups => {:user_id => @user.id}).
		where('end_time >= ?', Time.now)
    trainer_events = Event.
    where(:events => {:trainer_id => @user.id}).
    where('end_time >= ?', Time.now)
    csv_string = CSV.generate do |csv|
        csv << ["Subject", "Start Date", "Start Time", "End Date", "End Time", "All Day Event", "Description", "Location", "Private"]
        if !user_events.nil?
            user_events.each do |event|
                csv << [event.title, event.start_time.localtime.strftime("%D"), event.start_time.localtime.strftime("%r"), event.end_time.localtime.strftime("%D"), event.end_time.localtime.strftime("%r"), "FALSE", event.description, "Nebraska Innovation Studio", "TRUE"]
            end
        end
        if !trainer_events.nil?
            trainer_events.each do |event|
                csv << [event.title, event.start_time.localtime.strftime("%D"), event.start_time.localtime.strftime("%r"), event.end_time.localtime.strftime("%D"), event.end_time.localtime.strftime("%r"), "FALSE", event.description, "Nebraska Innovation Studio", "TRUE"]
            end
        end
    end

    content_type 'application/csv'
    attachment 'NIS_Trainings_and_Events.csv'
    csv_string
end