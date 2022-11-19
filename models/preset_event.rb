require 'active_record'
require 'models/preset_events_has_resource'

class PresetEvents < ActiveRecord::Base
    belongs_to :preset_events
    has_many :preset_events_has_resources

    def get_resource_ids
        self.preset_events_has_resources.map {|resource| resource.resources_id}
    end
end