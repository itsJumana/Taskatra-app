class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    @url = edit_password_url(token: @user.password_reset_token)
    Rails.logger.info "[PasswordReset] #{@user.email_address} → #{@url}"
    mail(to: @user.email_address, subject: "Reset your password")
  end
end
