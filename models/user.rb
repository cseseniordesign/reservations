require 'active_record'
require 'bcrypt'
require 'models/resource_authorization'
require 'models/event_signup'
require 'models/permission'
require 'models/resource'
require 'models/vehicle'
require 'models/user_has_permission'
require 'classes/emailer'

class User < ActiveRecord::Base
  has_many :resource_authorizations
  has_many :event_signups
  has_many :user_has_permissions
  has_many :permissions, through: :user_has_permissions
  has_many :alert_signups
  
  def authorized_resource_ids
    self.resource_authorizations.map {|res_auth| res_auth.resource_id}
  end

  def meets_resource_reservation_limit?(resource_id)
    # no limit for super user
    return true if self.is_super_user?

    # get resource to lookup limit
    resource = Resource.find(resource_id)

    # at limit if invalid resource
    return false if resource.nil?

    # no limit if limit is nil
    return true if resource.user_reservation_limit.nil?

    # check if user over reservation limit for resource and return boolean
    Reservation.joins(:resource).includes(:event).
        where(:resources => {:id => resource_id}).
        where(:user_id => id).
        where('end_time >= ?', Time.now).count < resource.user_reservation_limit.to_i
  end

  def get_authorization(resource_id)
    self.resource_authorizations.where(:resource_id => resource_id).first
  end

  def signed_up_event_ids
    self.event_signups.map {|event_signup| event_signup.event_id}
  end

  def is_current?
    !self.get_expiration_date.nil? && self.get_expiration_date >= Date.today
  end

  include BCrypt

  # now decides based on whether they have any admin permissions
  def is_admin?
    !self.permissions.empty?
  end
  alias_method :admin?, :is_admin?

  def is_super_user?
    self.permissions.include?(Permission.find(Permission::SUPER_USER))
  end
  alias_method :super_user?, :is_super_user?

  def has_permission?(id)
    self.permissions.include?(Permission.find(id))
  end

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def get_expiration_date
    expiration_date
  end

  def set_expiration_date(exp)
    if !exp.nil?
      if self.get_expiration_date.nil? && exp >= Date.today
        self.send_vehicle_information_update
        self.send_activation_email
      end
      if !self.get_expiration_date.nil? && self.get_expiration_date < Date.today && exp >= Date.today
        self.send_vehicle_information_update
      end
    end
    self.expiration_date = exp
    self.save
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def sortable_name
    "#{last_name}, #{first_name}"
  end

  def image_src
    "/images/user/#{id}/"
  end

  def set_image_data(params)
    if params[:imagedata] && !params[:imagedata].empty?
      self.imagemime = params[:imagedata][:type]
      self.imagedata = params[:imagedata][:tempfile].read if params[:imagedata][:tempfile].is_a?(Tempfile)
    end
    self.save
  end

  def remove_image_data
    self.imagemime = nil
    self.imagedata = nil
    self.save
  end

  def make_trainer_status
    self.is_trainer = 1
    unless self.has_permission?(Permission::EVENTS_ADMIN_READ_ONLY)
      self.permissions << Permission.find(Permission::EVENTS_ADMIN_READ_ONLY)
    end
    self.save
  end

  def remove_trainer_status
    self.is_trainer = 0
    unless !self.has_permission?(Permission::EVENTS_ADMIN_READ_ONLY)
      self.permissions.delete(Permission::EVENTS_ADMIN_READ_ONLY)
    end
    self.save
  end

  def send_membership_expiring_email
body = <<EMAIL
<p>Hello, #{self.full_name.rstrip}. Your Innovation Studio account is expiring soon! Our records show that your account expires on
#{self.expiration_date.strftime('%m-%d-%Y')}.
Please visit us to keep your membership active.
</p>

<p>We hope to see you soon!</p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, 'Nebraska Innovation Studio Membership Expiring', body)
  end

  def send_reset_password_email
    token = ''
    begin
      token = String.token
    end while User.find_by(:reset_password_token => token) != nil

    self.reset_password_token = token
    self.reset_password_expiry = Time.now + 1.day
    self.save

body = <<EMAIL
<p>We received a request to reset your Innovation Studio Manager password. Please click the link below to reset your password.</p>

<p><a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/reset_password/#{token}/">http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/reset_password/#{token}/</a></p>

<p>This link will only be active for 24 hours. If you did not request to reset your password, you may safely disregard this email.</p>

<p>Nebraska Innovation Studio</p>
EMAIL


    Emailer.mail(self.email, 'Nebraska Innovation Studio Password Reset', body)
  end

  def notify_trainer_of_new_event(event)
body = <<EMAIL
<p>Hi, #{self.full_name.rstrip}. You have been assigned as a trainer for <strong>#{event.title}</strong>. Don't forget that this event is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>Please visit your <a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/home/" target="_blank">home page</a> to confirm your assignment.</p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Assigned as Trainer for #{event.title}", body)
  end

  def notify_trainer_of_modified_event(event)
body = <<EMAIL
<p>Hi, #{self.full_name.rstrip}. You are receiving this email because an event you are training has been modified:</p>

<p><strong>#{event.title}</strong></p>

<p>You can see the event details on your <a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/home/" target="_blank">home page</a>.</p>


<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Event Modified: #{event.title}", body)
  end

  def notify_trainer_of_removal_from_event(event)
body = <<EMAIL
<p>Hi, #{self.full_name.rstrip}. You are receiving this email because you are no longer a trainer for the following event:</p>

<p><strong>#{event.title}</strong></p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Event Modified: #{event.title}", body)
  end

  def notify_trainer_of_deleted_event(event)
body = <<EMAIL
<p>Hi, #{self.full_name.rstrip}. You are receiving this email because the following event you are scheduled to train has been deleted:</p>

<p><strong>#{event.title}</strong></p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Event Deleted: #{event.title}", body)
  end

  def send_trainer_confirmation_reminder
body = <<EMAIL
<p>Hi, #{self.full_name.rstrip}. You are receiving this email because you have not confirmed your trainer assignment for one or more events. Please visit your <a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/home/" target="_blank">home page</a> to confirm an event.</p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Unconfirmed Training", body)
  end

  def send_vehicle_information_update
    vehicles = Vehicle.where(:user_id => self.id).all
    if vehicles.count > 0
      summary = ""
      vehicles.each do |vehicle|
        summary = summary + "<p>License Plate: #{vehicle.license_plate}, State: #{vehicle.state}, Make: #{vehicle.make}, Model: #{vehicle.model}</p>"
      end
body = <<EMAIL
<p>Hi, #{self.full_name.rstrip}. You're receiving this email because either your vehicle information has been updated or your account has been activated.</p> 

<p>Your most recent vehicle information is as follows:</p>
#{summary}
<p>Nebraska Innovation Studio</p>
EMAIL
      Emailer.mail(self.email, "Nebraska Innovation Studio - Vehicle Information Update", body, "innovationstudio@unl.edu")
    end
  end

  def send_activation_email
body = <<EMAIL
<strong>Thank you for attending New Member Orientation!</strong>

<p>To activate your user account please go to:</p>

<p>http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/login/ (Bookmark this link for future use) then enter the following:</p>

<p>User Name: #{self.username}</p>
<p>Temp Password: Welcome123</p>

<p>After logging in you must:</p>

<p>Click on “My Account” on the far right side of the red banner.
Go to “Add Vehicle”. Add your vehicle information. 
You can add up to 3 vehicles. You must park in the lot shown on the attached map.
<i>If any vehicle information changes you must update your account before attending NIS.</i>
<u>FAILURE TO DO SO WILL RESULT IN UP TO A $60 TICKET EVERY TIME YOU PARK.</u></p>

<strong>TRAININGS AND RESERVATIONS</strong>

<p>You are now able to sign up for any trainings or workshops via this webpage by clicking on the VIEW TRAININGS, VIEW WORKSHOPS, VIEW FULL CALENDAR tabs on the main page or under the MANAGE YOUR STUDIO drop down tab.</p>

<p>After you have been through required equipment training you will be able to reserve that equipment on the RESERVE EQUIPMENT tab on the main page or the drop-down tab. Not all equipment requires training or reservations.</p>

<strong>RENEWING YOUR MEMBERSHIP</strong>
<p>To renew your membership you must do so in person. We accept credit cards and UNL N Cards or cost object numbers. No checks or cash are accepted. Renew as soon as you enter the studio or you will receive a parking ticket.</p>

<p>Thank you and welcome aboard!</p>

<p>Your Studio Staff</p>
EMAIL
      Emailer.mail(self.email, "Nebraska Innovation Studio - Getting Started", body, '', {"new-member-orientation-parking-map.pdf" => File.read(File.expand_path("../public/pdf/new-member-orientation-parking-map.pdf", File.dirname(__FILE__)))})
  end

end