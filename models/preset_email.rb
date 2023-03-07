require 'active_record'

class PresetEmail < ActiveRecord::Base
  belongs_to :preset_emails
end