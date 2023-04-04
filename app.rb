require 'sinatra'
require 'models/user'
require 'models/service_space'
require 'models/event'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :domain => (ENV['RACK_ENV'] == 'development' ? nil : 'innovationstudio-manager.unl.edu'),
                           :secret => 'averymanteroldfatherbesseyhamilton',
                           :old_secret => 'averymanteroldfatherbesseyhamilton',
                           :expire_after => 30*24*60*60

Time.zone = "America/Chicago"

# this gives the user messages
def flash(type, header, message)
  session["notice"] ||= []
  session["notice"] << {
    :type => type,
    :header => header,
    :message => message
  }
end

SS_ID = ServiceSpace.where(:name => 'Innovation Studio').first.id

before do
    # site defaults
    @inline_body_script_content = ''
    @title = 'Innovation Studio Manager'
    @breadcrumbs = [
      {
        :href => 'https://www.unl.edu/',
        :text => 'Nebraska',
        :title => 'University of Nebraska&ndash;Lincoln Home'
      },
      {
        :href => 'https://innovationstudio.unl.edu/',
        :text => 'Innovation Studio'
      },
      {
        :href => '/',
        :text => 'Innovation Studio Manager'
      }
    ]

    session[:init] = true

    # check if the user is currently logged in
    if session.has_key?(:user_id)
        @user = (User.includes(:permissions).find(session[:user_id]) rescue nil)
    else
        @user = nil;
    end
end

def append_script_tag(src)
    @inline_body_script_content <<  "<script type=\"text/javascript\" src=\"#{src}\"></script>\n"
end

def append_script_declaration(content)
    @inline_body_script_content <<  "<script>#{content}</script>\n"
end

def has_permission?(permission)
    !@user.nil? && @user.has_permission?(permission)
end

def require_login(redirect_after_login=nil)
  if @user.nil?
    flash(:alert, 'You Must Login', 'That page requires you to be logged in. If you don\'t have an account, please sign up for <a href="/new_members/">New&nbsp;Member&nbsp;Orientation</a>.')
    if redirect_after_login.nil?
      redirect '/login/'
    else
      redirect "/login/?next_page=#{redirect_after_login}"
    end
  end
end

def drupal_node_lookup(key)
    nodes = {
        material_pricing: 79,
        sop_training_doc: 80,
        workshops_training_doc: 81,
        tips_training_doc: 82
    }

    return nodes[key] if nodes.key?(key)
end

not_found do
  @breadcrumbs << {:text => 'Not Found'}
  erb 'That page was not found.', :layout => :fixed
end

error do
  @breadcrumbs << {:text => 'Error'}
  flash(:danger, 'Sorry! There was an error.', "We apologize. A really bad error occurred and it didn't work. We're fixing this as we speak.")
  erb 'In the meantime, you can <a href="/">go back to the homepage</a>.', :layout => :fixed
end

get '/' do
  @breadcrumbs << {:text => 'Home'}
  redirect '/login/'
end

get '/images/user/:user_id/?' do
  user = User.find_by(:id => params[:user_id])
  if user.nil? || user.imagedata.nil?
    raise Sinatra::NotFound
  end

  return user.imagedata
end

get '/images/:event_id/?' do
  event = Event.find_by(:id => params[:event_id])
  if event.nil? || event.imagedata.nil?
    raise Sinatra::NotFound
  end

  return event.imagedata
end

Dir.glob("#{ROOT}/routes/*.rb") { |file| require file }
