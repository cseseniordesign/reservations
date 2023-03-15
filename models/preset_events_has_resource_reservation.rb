require 'active_record'
require 'models/preset_event'

class PresetEventsHasResourceReservation < ActiveRecord::Base
    belongs_to :preset_events
    belongs_to :resources
end