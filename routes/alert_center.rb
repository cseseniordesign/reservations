require 'models/alert'
require 'models/alert_signup'

get '/alert_center/:user_id/?' do

    user_alerts = AlertSignup.joins(:alert).where('user_id = ?', @user.id)
    alert_ids = Array.new

    user_alerts.each do |alert|
        alert_ids.append(alert.alert_id)
    end

    generalAlerts = Alert.all.where(category_id: 1).to_a
	generalAlerts.sort_by! {|generalAlerts| generalAlerts.name.downcase + generalAlerts.description.downcase}

    woodShopAlerts = Alert.all.where(category_id: 2).to_a
	woodShopAlerts.sort_by! {|woodShopAlerts| woodShopAlerts.name.downcase + woodShopAlerts.description.downcase}

    metalShopAlerts = Alert.all.where(category_id: 3).to_a
	metalShopAlerts.sort_by! {|metalShopAlerts| metalShopAlerts.name.downcase + metalShopAlerts.description.downcase}

    digitalFabricationAlerts = Alert.all.where(category_id: 4).to_a
	generalAlerts.sort_by! {|digitalFabricationAlerts| digitalFabricationAlerts.name.downcase + digitalFabricationAlerts.description.downcase}

    artAlerts = Alert.all.where(category_id: 5).to_a
	artAlerts.sort_by! {|artAlerts| artAlerts.name.downcase + artAlerts.description.downcase}

    erb :alert_center, :layout => :fixed, :locals => {
        :generalAlerts => generalAlerts,
        :woodShopAlerts => woodShopAlerts,
        :metalShopAlerts => metalShopAlerts,
        :digitalFabricationAlerts => digitalFabricationAlerts,
        :artAlerts => artAlerts,
        :alert_ids => alert_ids
    }

end

post '/alert_center/:user_id/?' do

    newAlerts = Array.new

    params.each do |key, value|
        if key.start_with?('alert_id_')
            newAlerts.append(params[key].to_i)
        end
    end

    users = AlertSignup.where(user_id: @user.id).all
    users.destroy_all

    newAlerts.each do |alert|
        user_alert = AlertSignup.create(user_id: @user.id, alert_id: alert)
    end

    flash(:success, 'Alerts Updated', "Your selected alerts have been saved.")

    redirect '/home/'

end