require 'active_record'
require 'models/preset_events_has_resource'
require 'models/preset_events_has_resource_reservation'

class PresetEvents < ActiveRecord::Base
    belongs_to :preset_events
    has_many :preset_events_has_resources
    has_many :preset_events_has_resource_reservations

    def get_resource_ids
        self.preset_events_has_resources.map {|resource| resource.resources_id}
    end

	def get_resource_reservations_ids
        self.preset_events_has_resource_reservations.map {|resource| resource.resource_id}
    end

    def has_reservation
		!self.preset_events_has_resource_reservations.nil? && self.preset_events_has_resource_reservations.count > 0
	end

	def has_tool_reservation(tool_id)
	    return false unless self.has_reservation
	    self.preset_events_has_resource_reservations.each do |r|
	        return true if !r.resource_id.nil? && r.resource_id == tool_id
	    end
	    false
	end
end