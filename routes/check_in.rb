require 'models/check_ins'

get '/check_in/?' do

    studios = ['Woodshop', 'Metalshop', 'Digital Lab', 'Digital Fabrication', 'Textiles', 'Ceramics', 'Prototyping']

    reasons = ['Training', 'Personal Project', 'Buisness Project', 'Class Project']

    erb :check_in, :layout => :fixed_no_toolbar, :locals => {
       :studios => studios,
       :reasons => reasons,
    } 
end

post '/check_in/?' do

    checkIn = CheckIn.new

    checkIn.user_id = @user.id
    checkIn.username = @user.username
    checkIn.name = @user.full_name
    checkIn.university_status = @user.university_status
    checkIn.datetime = Time.current

    if !@user.expiration_date.nil? && @user.expiration_date > Date.today
        checkIn.expired = "No"
    else
        checkIn.expired = "Yes"
    end

    checkIn.visit_reason = params[:ReasonOfVisit]
    checkIn.studio_used = params[:StudioUsed]

    checkIn.save
    
    session.clear
    redirect '/check_in_login'
end