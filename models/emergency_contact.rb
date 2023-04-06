require 'active_record'

class EmergencyContact < ActiveRecord::Base
  belongs_to :emergency_contacts
end