require 'active_record'

class Vehicle < ActiveRecord::Base
  belongs_to :vehicles
end