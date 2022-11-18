require 'active_record'

class PresetEvent < ActiveRecord::Base
    belongs_to :preset_events
    has_many :preset_events_has_resources, dependent: :destroy

    # implement this method
    # def get_resource_ids
    #     self.resource_authorizations.map {|res_auth| res_auth.resource_id}
    # end
end