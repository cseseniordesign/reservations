require 'models/check_ins'
require 'models/studio_space.rb'


USER_STATII = [
    'None',
    'NU Student (UNL, UNO, UNMC, UNK)',
    'NU Faculty (UNL, UNO, UNMC, UNK)',
    'NU Staff (UNL, UNO, UNMC, UNK)',
    'NU Alumni (UNL, UNO, UNMC, UNK)',
    'Non-NU Student (All Other Institutions)',
    'NIS/NIC Partner (NIS/NIC Affiliated Business Employee, Military Veterans)',
    'Community'
]

before '/admin/view_check_in*' do
    unless has_permission?(Permission::MANAGE_USERS) || has_permission?(Permission::SUPER_USER)
        raise Sinatra::NotFound
    end
end

get '/admin/view_check_in/?' do
    @breadcrumbs << {:text => 'View Check Ins'}

    name = params[:name]
    username = params[:username]
    university_status = params[:university_status]
    studio_used = params[:studio_used]
    visit_reason = params[:visit_reason]
    check_in_date = params[:check_in_date]


    checkIns = []

    if params.length > 0
        checkIns = CheckIn.all
    else
        checkIns = CheckIn.where(datetime: (Time.current - 1.days)..Time.current)
    end

    unless name.blank?
        checkIns = checkIns.where("name LIKE ?", "%#{name}%")
    end

    unless username.blank?
        checkIns = checkIns.where("username LIKE ?", "%#{username}%")
    end

    unless university_status.blank?
        checkIns = checkIns.where("university_status LIKE ?", "%#{university_status}%")
    end

    unless studio_used.blank?
        checkIns = checkIns.where("studio_used LIKE ?", "%#{studio_used}%")
    end

    unless visit_reason.blank?
        checkIns = checkIns.where("visit_reason LIKE ?", "%#{visit_reason}%")
    end

    unless check_in_date.blank?   
        converted_date = Date.strptime(check_in_date, "%m/%d/%Y")
        checkIns = checkIns.in_day(converted_date)
    end

    checkIns.order(datetime: :desc)

    counts = CheckIn.where(datetime: (Time.current - 7.days)..Time.current).group(:studio_used).count
    studios = StudioSpace.pluck(:name)

    reasons = ['Training', 'Personal Project', 'Business Project', 'Class Project']

    erb :'admin/view_check_in', :layout => :fixed, :locals => {
        :checkIns => checkIns,
        :counts => counts,
        :studios => studios,
        :name => name,
        :username => username,
        :reasons => reasons,
        :university_status => university_status,
        :studio_used => studio_used,
        :visit_reason => visit_reason,
        :check_in_date => check_in_date,
    }

end

get '/admin/view_check_in/studio_spaces/?' do
    studios = StudioSpace.all
    @breadcrumbs << {:text => 'Manage Studio Spaces'}
    erb :'admin/manage_studio_spaces', :layout => :fixed, :locals => {
        :studios => studios
    }
end 

post '/admin/view_check_in/studio_spaces/?' do
	require_login

	if  params[:name].blank?
		flash :error, 'Error', 'Please enter studio space name'
		redirect back
	end

	studio = StudioSpace.new
	studio.name = params[:name]
	studio.save

	flash(:success, 'Studio Created', "Your studio #{studio.name} has been created.")
	redirect '/admin/view_check_in/studio_spaces/'
end

post '/admin/view_check_in/studio_spaces/:studio_id/delete/?' do
	require_login

	# check that this is a valid studio
	studio = StudioSpace.find_by(:id => params[:studio_id])
	if studio.nil?
		flash(:alert, 'Not Found', 'That studio does not exist.')
		redirect '/admin/view_check_in/studio_spaces/'
	end

	studio.destroy
	flash(:success, 'Studio Deleted', "Your studio #{studio.name} has been deleted.")
	redirect '/admin/view_check_in/studio_spaces/'
end

