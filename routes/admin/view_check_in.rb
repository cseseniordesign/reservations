require 'models/check_ins'

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
    studio_status = params[:studio_status]
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

    unless studio_status.blank?
        checkIns = checkIns.where("studio_status LIKE ?", "%#{studio_status}%")
    end

    unless studio_used.blank?
        checkIns = checkIns.where("studio_used LIKE ?", "%#{studio_used}%")
    end

    unless visit_reason.blank?
        checkIns = checkIns.where("visit_reason LIKE ?", "%#{visit_reason}%")
    end

    unless check_in_date.blank?   
        converted_date = Date.strptime(check_in_date, "%m/%d/%Y").strftime("%Y-%m-%d")
        checkIns = checkIns.where("STR_TO_DATE(datetime, '%Y-%m-%d') = ?", converted_date)
    end

    checkIns.order(datetime: :desc)

    counts = CheckIn.where(datetime: (Time.current - 7.days)..Time.current).group(:studio_used).count
    studios = ['Woodshop', 'Metalshop', 'Digital Lab', 'Digital Fabrication', 'Textiles', 'Ceramics', 'Prototyping']

    reasons = ['Training', 'Personal Project', 'Buisness Project', 'Class Project']

    erb :'admin/view_check_in', :layout => :fixed, :locals => {
        :checkIns => checkIns,
        :counts => counts,
        :studios => studios,
        :name => name,
        :username => username,
        :reasons => reasons,
        :studio_status => studio_status,
        :studio_used => studio_used,
        :visit_reason => visit_reason,
        :check_in_date => check_in_date,
    }

end