require 'active_record'

class AlertSignup < ActiveRecord::Base
	belongs_to :alert
    belongs_to :user
end