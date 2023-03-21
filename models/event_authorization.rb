require 'active_record'

class EventAuthorization < ActiveRecord::Base
	belongs_to :event
    belongs_to :resource
end

