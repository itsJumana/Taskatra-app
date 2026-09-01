module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private
      def set_current_user
        return unless (token = cookies[:session_token])

        claims = JsonWebToken.decode(token)
        return unless claims

        if session = Session.find_by(id: claims[:session_id])
          self.current_user = session.user
        end
      end
  end
end
