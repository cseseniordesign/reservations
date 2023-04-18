require 'models/check_ins'

# before '/admin/view_check_in*' do
#     unless has_permission?(Permission::MANAGE_USERS) || has_permission?(Permission::SUPER_USER)
#         raise Sinatra::NotFound
#     end
# end

get '/admin/view_check_in/?' do
    @breadcrumbs << {:text => 'View Check Ins'}
    checkIns = []
    checkIns = CheckIn.order(datetime: :desc)

    counts = CheckIn.where(datetime: (Time.current - 7.days)..Time.current).group(:studio_used).count
    studios = ['Woodshop', 'Metalshop', 'Digital Lab', 'Digital Fabrication', 'Textiles', 'Ceramics', 'Prototyping']

    erb :'admin/view_check_in', :layout => :fixed, :locals => {
        :checkIns => checkIns,
        :counts => counts,
        :studios => studios,
    }

end