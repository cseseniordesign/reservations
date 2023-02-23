require 'active_record'

class Alert < ActiveRecord::Base
    has_many :alert_signups

    ALERT_CATEGORY_GENERAL_ALERTS = 1
    ALERT_CATEGORY_WOODSHOP_ALERTS = 2
    ALERT_CATEGORY_METALSHOP_ALERTS = 3
    ALERT_CATEGORY_DIGITAL_FABRICATION_ALERTS = 4
    ALERT_CATEGORY_ART_ALERTS = 5

   def self.category_options
        {
            ALERT_CATEGORY_GENERAL_ALERTS => 'General Alerts',
            ALERT_CATEGORY_WOODSHOP_ALERTS => 'Woodshop Alerts',
            ALERT_CATEGORY_METALSHOP_ALERTS => 'Metalshop Alerts',
            ALERT_CATEGORY_DIGITAL_FABRICATION_ALERTS => 'Digital Fabrication Alerts',
            ALERT_CATEGORY_ART_ALERTS => 'Art Alerts',
        }
    end

    def self.valid_category_id?(category_id)
        self.category_options.key?(category_id.to_i)
    end

    def category_name
        return self.class.category_options[category_id] if self.class.category_options.include?(category_id)
        'Other'
    end

end