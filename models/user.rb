require 'active_record'
require 'bcrypt'
require 'models/resource_authorization'
require 'models/event_signup'
require 'models/permission'
require 'models/resource'
require 'models/user_has_permission'
require 'classes/emailer'

class User < ActiveRecord::Base
  has_many :resource_authorizations
  has_many :event_signups
  has_many :user_has_permissions
  has_many :permissions, through: :user_has_permissions

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
    self.save
  end

  def remove_trainer_status
    self.is_trainer = 0
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
<p>Hi, #{self.full_name}. You have been assigned as a trainer for <strong>#{event.title}</strong>. Don't forget that this event is</p>

<p><strong>#{event.start_time.in_time_zone.strftime('%A, %B %d at %l:%M %P')}</strong>.</p>

<p>Please visit your <a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/home/" target="_blank">home page</a> to confirm your assignment.</p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Assigned as Trainer for #{event.title}", body)
  end

  def notify_trainer_of_modified_event(event)
body = <<EMAIL
<p>Hi, #{self.full_name}. You are receiving this email because an event you are training has been modified:</p>

<p><strong>#{event.title}</strong></p>

<p>You can see the event details on your <a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/home/" target="_blank">home page</a>.</p>


<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Event Modified: #{event.title}", body)
  end

  def notify_trainer_of_removal_from_event(event)
body = <<EMAIL
<p>Hi, #{self.full_name}. You are receiving this email because you are no longer a trainer for the following event:</p>

<p><strong>#{event.title}</strong></p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Event Modified: #{event.title}", body)
  end

  def notify_trainer_of_deleted_event(event)
body = <<EMAIL
<p>Hi, #{self.full_name}. You are receiving this email because the following event you are scheduled to train has been deleted:</p>

<p><strong>#{event.title}</strong></p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Event Deleted: #{event.title}", body)
  end

  def send_trainer_confirmation_reminder
body = <<EMAIL
<p>Hi, #{self.full_name}. You are receiving this email because you have not confirmed your trainer assignment for one or more events. Please visit your <a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/home/" target="_blank">home page</a> to confirm an event.</p>

<p>Nebraska Innovation Studio</p>
EMAIL

    Emailer.mail(self.email, "Nebraska Innovation Studio - Unconfirmed Training", body)
  end

end