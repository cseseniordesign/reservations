require 'active_record'

class Event < ActiveRecord::Base
	has_many :event_signups, :dependent => :destroy
	has_many :reservation, :dependent => :destroy
	has_many :event_authorizations, :dependent => :destroy
	belongs_to :location
	belongs_to :event_type
	alias_method :type, :event_type
	alias_method :signups, :event_signups

    EVENT_TYPE_ID_NEW_MEMBER_ORIENTATION = 1
    EVENT_TYPE_ID_MACHINE_TRAINING = 2
    EVENT_TYPE_ID_ADV_SKILL_BASED_WORKSHOP = 3
    EVENT_TYPE_ID_CREATION_WORKSHOP = 4
    EVENT_TYPE_ID_GENERAL_WORKSHOP = 5
    EVENT_TYPE_ID_FREE_EVENT = 6
    EVENT_TYPE_ID_RSVP_ONLY_EVENT = 7
    EVENT_TYPE_ID_TOUR = 8

	def self.type_options
        {
            EVENT_TYPE_ID_NEW_MEMBER_ORIENTATION => 'New Member Orientation',
            EVENT_TYPE_ID_MACHINE_TRAINING => 'Machine Training',
			EVENT_TYPE_ID_ADV_SKILL_BASED_WORKSHOP => 'Advanced Skill-Based Workshop',
			EVENT_TYPE_ID_CREATION_WORKSHOP => 'Creation Workshop',
			EVENT_TYPE_ID_GENERAL_WORKSHOP => 'General Workshop',
			EVENT_TYPE_ID_FREE_EVENT => 'Free Event',
			EVENT_TYPE_ID_RSVP_ONLY_EVENT => 'RSVP Only Event',
        }
    end

    EVENT_TYPES_NOT_ALLOWED_FOR_SIGNUP = [EVENT_TYPE_ID_CREATION_WORKSHOP]

	scope :in_day, ->(time) {
		today = time.in_time_zone.midnight
		tomorrow = (time.in_time_zone.midnight + 1.day + 1.hour).in_time_zone.midnight
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', today.getutc, tomorrow.getutc, today.getutc, tomorrow.getutc)
	}

	scope :in_week, ->(time) {
		last_sunday = time.in_time_zone.week_start
		next_sunday = (time.in_time_zone.week_start + 1.week + 1.hour).in_time_zone.week_start
		where('(start_time >= ? AND start_time < ?) OR (end_time >= ? AND end_time < ?)', last_sunday.getutc, next_sunday.getutc, last_sunday.getutc, next_sunday.getutc)
	}

	# returns length in minutes. If start or end is nil, returns 0
	def length
		if end_time.nil? || start_time.nil?
			return 0
		end
		((end_time - start_time) / 60).to_i
	end

	def info_link
		case type.description
		when 'New Member Orientation'
			"/new_members/sign_up/#{id}/"
		else
			"/events/#{id}/"
		end
	end

	def edit_link
		"/admin/events/#{id}/edit/"
	end

	def has_reservation
		!self.reservation.nil? && self.reservation.count > 0
	end

	def has_tool_reservation(tool_id)
	    return false unless self.has_reservation
	    self.reservation.each do |r|
	        return true if !r.resource.nil? && r.resource.id == tool_id
	    end
	    false
	end

	def has_authorization
		!self.event_authorizations.nil? && self.event_authorizations.count > 0
	end

	def image_src
		"/images/#{id}/"
	end

	def set_data(params)
		self.title = params[:title]
		self.description = params[:description]
		self.admin_notes = params[:admin_notes]
		self.start_time = calculate_time(params[:start_date], params[:start_time_hour], params[:start_time_minute], params[:start_time_am_pm])
		self.end_time = calculate_time(params[:end_date], params[:end_time_hour], params[:end_time_minute], params[:end_time_am_pm])
		self.event_type_id = params[:type]
		self.trainer_id = params[:trainer]
		self.location_id = params[:location]
		self.max_signups = params[:limit_signups] == 'on' ? params[:max_signups].to_i : nil
		self.service_space_id = SS_ID
		self.is_private = params[:is_private]
		self.save
	end

	def set_image_data(params)
		if params[:imagedata]
			self.imagemime = params[:imagedata][:type]
			self.imagedata = params[:imagedata][:tempfile].read if params[:imagedata][:tempfile].is_a?(Tempfile)
		end
		self.save
	end

	def remove_image_data
		self.imagemime = nil
		self.imagedata = nil
		self.save
	end

	def signup_allowed_for_type?
	    !EVENT_TYPES_NOT_ALLOWED_FOR_SIGNUP.include?(self.type.id)
	end

	def free_event_type?
	    self.type.id == EVENT_TYPE_ID_FREE_EVENT
	end

	def machine_training_event_type?
	    self.type.id == EVENT_TYPE_ID_MACHINE_TRAINING
	end
end