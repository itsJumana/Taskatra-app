module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      return unless (token = cookies[:session_token])

      claims = JsonWebToken.decode(token)
      Session.find_by(id: claims[:session_id]) if claims
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        token = JsonWebToken.encode({ session_id: session.id })
        cookies[:session_token] = { value: token, httponly: true, same_site: :lax, expires: 30.days.from_now }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_token)
    end
end
