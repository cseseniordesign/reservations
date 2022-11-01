require 'models/user'
require 'models/permission'

before '/admin/email*' do
	unless has_permission?(Permission::MANAGE_EMAILS)
		raise Sinatra::NotFound
	end
end

get '/admin/email/?' do
	@breadcrumbs << {:text => 'Admin Emails'}
	erb :'admin/emails', :layout => :fixed
end

get '/admin/email/send/?' do
	@breadcrumbs << {:text => 'Admin Emails', :href => '/admin/email/'}
	@breadcrumbs << {:text => 'Send Email'}
	users = User.all
	tools = Resource.where(:service_space_id => SS_ID).order(:name).all

	erb :'admin/send_email', :layout => :fixed, :locals => {
		:users => users,
		:tools => tools
	}
end

post '/admin/email/send/?' do
	users_to_send_to = []
	all_users = User.where(:service_space_id => SS_ID).where.not("space_status LIKE ?", "%no_email").all

	# compile the list based on what was checked
	if params.checked?('send_to_all_non_admins')
		users = all_users.where(:is_admin => false)
		users_to_send_to += users
	end
	if params.checked?('send_to_all_users')
		users = all_users
		users_to_send_to += users
	end
	if params.checked?('send_to_all_students')
		users = all_users.where(:university_status => ['UNL Undergrad','UNL Grad','Other Student'])
		users_to_send_to += users
	end
	if params.checked?('send_to_all_facstaff')
		users = all_users.where(:university_status => ['UNL Staff','UNL Faculty','Emeritus UNL Faculty'])
		users_to_send_to += users
	end
	if params.checked?('send_to_specific_user')
		params[:specific_user].each do |id|
			user = all_users.find_by(:id => id)
			users_to_send_to << user unless user.nil?
		end
	end
	todays_date = Date.today.strftime("%Y-%m-%d")
	if params.checked?('send_to_all_active_users')
		users = all_users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') >= ?", todays_date)
		users_to_send_to += users
	end
	if params.checked?('send_to_all_inactive_users')
		users = all_users.where("STR_TO_DATE(expiration_date, '%Y-%m-%d') <= ?", todays_date)
		users_to_send_to += users
	end
	if params.checked?('send_to_all_with_tool_authorization')
		params[:tool_authorization].each do |id|
			users = all_users.select { |user| user.authorized_resource_ids.include?(id) }
			unless users.nil?
				users.each do |user|
					users_to_send_to << user
				end
			end
		end
	end
	
	# compact and uniqify the list
	users_to_send_to = users_to_send_to.compact.uniq do |user|
		user.id
	end

	# check on attachments
 	attachments = {}
 	params.select {|k,v| k.start_with?('file_')}.each do |key, file_hash|
 		attachments[file_hash[:filename]] = file_hash[:tempfile].read
 	end
 	attachments = nil if attachments.empty?

	# add the option to opt out if necessary
	body = params[:body]
	if params.checked?('email_opt_out')
		body = <<-EMAIL
		#{body}
		<hr>If you no longer want to receive emails from us you can adjust your email preferences <a href="http://#{ENV['RACK_ENV'] == 'development' ? 'localhost:9393' : 'innovationstudio-manager.unl.edu'}/opt_out/" target="_blank">here</a>.
		EMAIL
	end

	# correctly choose how to send
	if users_to_send_to.count == 1
		Emailer.mail(users_to_send_to[0].email, params[:subject], body, '', attachments)
		output = users_to_send_to[0].full_name
	elsif users_to_send_to.count > 1
		bcc = users_to_send_to.map(&:email).join(',')
		Emailer.mail('', params[:subject], body, bcc, attachments)
		output = "#{users_to_send_to.count} users"
	else
		flash :error, 'No Users Selected', 'This email was not sent to any users'
		redirect back
	end

	flash :success, 'Email sent', "Your email was sent to #{output}."
	redirect '/admin/email/send/'
end