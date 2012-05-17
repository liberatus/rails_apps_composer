if config['mailchimp_bootstrap']
  gem 'mailchimp', git: 'git://github.com/mailchimp/mailchimp-gem.git'
  gem 'rack-www'
  gem 'omniauth'
  gem 'omniauth-mailchimp'
  gem 'heroku'
  gem 'dalli'
  
  gem 'sqlite3', :group => :development
  
  gem 'pg', :group => :production
  
  gem 'twitter-bootstrap-rails', '>= 2.0.3', :group => :assets
  # please install gem 'therubyracer' to use Less
  gem 'therubyracer', :group => :assets, :platform => :ruby
  recipes << 'bootstrap'
  recipes << 'jsruntime'

  after_bundler do
    #
    #
    # TWITTER BOOTSTRAP 
    #
    #
    
    generate 'bootstrap:install'
    
    
    # add a humans.txt file
    get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/humans.txt', 'public/humans.txt'
    # install a front-end framework for HTML5 and CSS3
    remove_file 'app/assets/stylesheets/application.css'
    remove_file 'app/views/layouts/application.html.erb'
    remove_file 'app/views/layouts/application.html.haml'
    
    # ERB version of a complex application layout using Twitter Bootstrap
    get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/twitter-bootstrap/views/layouts/application.html.erb', 'app/views/layouts/application.html.erb'
    get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/twitter-bootstrap/views/layouts/_messages.html.erb', 'app/views/layouts/_messages.html.erb'
    # complex css styles using Twitter Bootstrap
    get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/twitter-bootstrap/assets/stylesheets/application.css.scss', 'app/assets/stylesheets/application.css.scss'
    
    remove_file 'app/assets/stylesheets/application.css' # just created application.css.scss above
    insert_into_file 'app/assets/stylesheets/bootstrap_and_overrides.css.less', "body { padding-top: 60px; }\n", :after => "@import \"twitter/bootstrap/bootstrap\";\n"
    
    get 'https://raw.github.com/RailsApps/rails3-application-templates/master/files/navigation/omniauth/_navigation.html.erb', 'app/views/layouts/_navigation.html.erb'
    
    gsub_file 'app/views/layouts/application.html.erb', /App_Name/, "#{app_name.humanize.titleize}"
    gsub_file 'app/views/layouts/_navigation.html.erb', /App_Name/, "#{app_name.humanize.titleize}"
    
    
    #
    #
    #     OMNIAUTH
    #
    #
    create_file 'config/initializers/omniauth.rb' do <<-RUBY
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :mailchimp, 'KEY', 'SECRET'
end
RUBY
    end

    # add routes
    route "match '/auth/failure' => 'sessions#failure'"
    route "match '/signout' => 'sessions#destroy', :as => :signout"
    route "match '/signin' => 'sessions#new', :as => :signin"
    route "match '/auth/:provider/callback' => 'sessions#create'"
    route "resources :users, :only => [ :show, :edit, :update ]"

    # We have to use single-quote-style-heredoc to avoid interpolation.
    create_file 'app/controllers/sessions_controller.rb' do <<-'RUBY'
class SessionsController < ApplicationController

  def create
    auth = request.env["omniauth.auth"]
    user = User.where(:uid => auth['uid']).first || User.create_with_omniauth(auth)
    session[:user_id] = user.id
    redirect_to root_url, :notice => 'Signed in!'
  end

  def destroy
    reset_session
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
RUBY
    end

    # Don't use single-quote-style-heredoc: we want interpolation.
    inject_into_class 'app/controllers/sessions_controller.rb', 'SessionsController' do <<-RUBY

  def new
    redirect_to '/auth/mailchimp'
  end

RUBY
    end

    inject_into_file 'app/controllers/application_controller.rb', :before => 'end' do <<-RUBY
  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?

  private
    def current_user
      begin
        @current_user ||= User.find(session[:user_id]) if session[:user_id]
      rescue Mongoid::Errors::DocumentNotFound
        nil
      end
    end

    def user_signed_in?
      return true if current_user
    end

    def correct_user?
      @user = User.find(params[:id])
      unless current_user == @user
        redirect_to root_url, :alert => "Access denied."
      end
    end

    def authenticate_user!
      if !current_user
        redirect_to root_url, :alert => 'You need to sign in for access to this page.'
      end
    end

RUBY
    end
    
    #
    #
    #  MAILCHIMP assets and user model
    #
    #
    get 'https://s3.amazonaws.com/mailchimp-bootstrap-assets/noise.png', 'app/assets/images/noise.png'

    generate(:model, "user apikey:string uid:string name:string email:string")

    gsub_file 'app/models/user.rb', /end/ do
    <<-RUBY
  attr_accessible :uid, :name, :email, :apikey

  def api
    @api ||= Mailchimp::API.new(apikey)
  end
  
  def self.create_with_omniauth(auth)
    create! do |user|
      user.apikey = "#{auth['credentials']['token']}-#{@auth['extra']['metadata']['dc']}"
      user.uid = auth['uid']
      if auth['info']
         user.name = auth['info']['name'] || ""
         user.email = auth['info']['email'] || ""
      end
    end
  end
  
end
RUBY
    end

    append_file 'app/assets/stylesheets/bootstrap_overrides.css.less' do
    <<-TXT
// Use Mailchimp layout
body{
  padding-top: 120px;
  background: #DDD9D8 image-url('noise.png');
}
body > .container{
  background-color: white;
  padding: 20px;
  border-radius: 0 0 10px 10px;
}
.navbar-inner{
  padding: 30px;
  background-color: #46BCD2;
  background-image: -moz-linear-gradient(top, #46BCD2, #46BCD2);
  background-image: -ms-linear-gradient(top, #46BCD2, #46BCD2);
  background-image: -webkit-gradient(linear, 0 0, 0 100%, from(#46BCD2), to(#46BCD2));
  background-image: -webkit-linear-gradient(top, #46BCD2, #46BCD2);
  background-image: -o-linear-gradient(top, #46BCD2, #46BCD2);
  background-image: linear-gradient(top, #46BCD2, #46BCD2);
  background-repeat: repeat-x;
  filter: progid:DXImageTransform.Microsoft.gradient(startColorstr='#46BCD2', endColorstr='#46BCD2', GradientType=0);
}
.span12, .container{
  max-width: 1220px;
}
.navbar .brand{
  font-size: 40px;
}
.navbar .nav > li > a {
  line-height: 40px;
  color: white;
  padding: 13px 10px 11px;
  font-size: 20px;
}
.navbar .nav > li > a:hover{
  color: #333;
}
@media (max-width: 979px){
  body{
    padding-top: 0;
  }
  .navbar-fixed-top{
    margin-bottom: 0;
  }
  .navbar .nav > li > a:hover {
  color: white;
  }
  .navbar .nav > li > a:hover, .navbar .dropdown-menu a:hover {
  background-color: darken(@blue,10%);
  }
}





// 
//  Use Mailchimp color scheme
//
// Grays
// -------------------------
@black:                 #000;
@grayDarker:            darken(@grayDark,10%);
@grayDark:              #3F3F38;
@gray:                  #787975;
@grayLight:             lighten(@gray,10%);
@grayLighter:           #B7B7B5;
@white:                 #fff;


// Accent colors - straight from mailchimp.com/about/brand-assets/
// -------------------------
@blue:                  #45bcd2;
@blueDark:              darken(@blue,10%);
@green:                 #72C1B0;
@red:                   #E95C41;
@yellow:                #F2E000;
@orange:                #ED5D3B;
@pink:                  #F2BDB9;
@purple:                #914592;


// Buttons
// -------------------------
@btnBackground:                     @white;
@btnBackgroundHighlight:            darken(@white, 10%);
@btnBorder:                         #ccc;

@btnPrimaryBackground:              @orange;
@btnPrimaryBackgroundHighlight:     spin(@btnPrimaryBackground, 15%);

@btnInfoBackground:                 #5bc0de;
@btnInfoBackgroundHighlight:        #2f96b4;

@btnSuccessBackground:              @green;
@btnSuccessBackgroundHighlight:     darken(@green,10%);

@btnWarningBackground:              lighten(@orange, 15%);
@btnWarningBackgroundHighlight:     @orange;

@btnDangerBackground:               #ee5f5b;
@btnDangerBackgroundHighlight:      #bd362f;

@btnInverseBackground:              @gray;
@btnInverseBackgroundHighlight:     @grayDarker;



TXT
    end 
   
  end
end

__END__

name: mailchimp_bootstrap
description: "Bootstrap a mailchimp integrated application"
author: wnadeau

run_after: []
category: other
tags: [template, bootstrap, configuration]

config:
  - mailchimp_bootstrap:
      type: boolean
      prompt: Would you like to start a fresh Mailchimp integrated application?
