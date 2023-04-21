require 'models/announcements'

before '/admin/announcements*' do
	unless has_permission?(Permission::SUPER_USER)
		raise Sinatra::NotFound
	end
end

get '/admin/announcements/?' do
	require_login
	@breadcrumbs << {:text => 'Admin Announcements', :href => '/admin/announcements/'}
	@breadcrumbs << {:text => 'Announcements'}
	announcements = Announcements.first		# there should only be one announcement

	erb :'admin/announcements', :layout => :fixed, :locals => {
		:announcements => announcements
	}
end

post '/admin/announcements/post/?' do
	require_login

	# if an announcement exists, update it, otherwise create a new one
	if Announcements.first
		announcements = Announcements.first
	else
		announcements = Announcements.new
	end
	announcements.text = params[:text]
	if announcements.text.empty?
		flash :error, 'Error', 'Please enter the text for the announcement'
		redirect back
	end
	announcements.save

	flash :success, 'Success', 'Your announcement has been created!'
	redirect '/admin/announcements/'
end

post '/admin/announcements/delete/?' do
	require_login
	announcements = Announcements.first

	if announcements.nil?
		flash :error, 'Error', 'There is no announcement to delete'
		redirect '/admin/announcements/'
	end

	announcements.destroy

	flash :success, 'Success', 'Your announcement has been deleted!'
	redirect '/admin/announcements/'
end