require 'pony'

class Emailer

  TYPE_PROMOTIONAL = 1
  TYPE_FUNCTIONAL = 2
  TYPE_NEWS = 3
  TYPE_REMINDER = 4

  def self.type_options
      {
        TYPE_PROMOTIONAL => 'Promotional',
        TYPE_FUNCTIONAL => 'Functional',
        TYPE_NEWS => 'News',
        TYPE_REMINDER => 'Reminder',
      }
  end

  def type_name
    return self.class.type_options[type_id] if self.class.type_options.include?(type_id)
    'Other'
  end

  RECIPIENT_BYTE_LIMIT = 2048

  def self.mail(to, subject, body, bcc = "", attachments = nil)
    if (bcc.bytesize > RECIPIENT_BYTE_LIMIT)
      bcc_groups = self.breakup_recipient(bcc)
      bcc_groups.each do |bcc_group|
        Pony.mail({
          :to => to,
          :bcc => bcc_group,
          :subject => subject,
          :html_body => body,
          :from => 'innovationstudio@unl.edu',
          :via => self.method,
          :via_options => self.method_options,
          :attachments => attachments
        })
      end
    else
      Pony.mail({
        :to => to,
        :bcc => bcc,
        :subject => subject,
        :html_body => body,
        :from => 'innovationstudio@unl.edu',
        :via => self.method,
        :via_options => self.method_options,
        :attachments => attachments
      })
    end
  end

  def self.breakup_recipient(recipient)
    recipients = recipient.split(',').uniq
    recipient_groups = Array.new
    list = test_list = ''
    recipients.each do |r|
      test_list << "#{r.strip},"
      if test_list.bytesize > RECIPIENT_BYTE_LIMIT
        recipient_groups.push(list.chomp(','))
        list = test_list = ''
      else
        list = test_list
      end
    end
    recipient_groups.push(list.chomp(',')) unless list.empty?
    recipient_groups
  end

  private 

  def self.method
    if ENV['RACK_ENV'] == 'development'
      :sendmail
#     :smtp
    else
      :sendmail
    end
  end

  def self.method_options
    if ENV['RACK_ENV'] == 'development'
      {
        :address => '127.0.0.1',
        :port => '1025'
      }
    else
      {}
    end
  end
end
